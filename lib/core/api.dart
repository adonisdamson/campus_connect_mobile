import 'package:dio/dio.dart';
import 'config.dart';
import 'storage.dart';

/// Thin Dio wrapper: attaches the access token, transparently refreshes on 401,
/// and normalises the `{ success, ... }` envelope used by the API.
class Api {
  Api._();
  static final Api instance = Api._();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(_AuthInterceptor());

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) =>
      _send(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _send(() => _dio.put(path, data: body));

  Future<Map<String, dynamic>> patch(String path, [Map<String, dynamic>? body]) =>
      _send(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> delete(String path) => _send(() => _dio.delete(path));

  /// Multipart upload of a single file. Dio swaps the Content-Type to
  /// multipart/form-data automatically when the body is FormData.
  Future<Map<String, dynamic>> uploadFile(String path, String filePath,
      {String fieldName = 'file', String? fileName, Map<String, String>? fields}) async {
    final form = FormData.fromMap({
      ...?fields,
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _send(() => _dio.post(path, data: form));
  }

  Future<Map<String, dynamic>> _send(Future<Response> Function() fn) async {
    try {
      final res = await fn();
      final data = res.data;
      return data is Map<String, dynamic> ? data : {'success': true, 'data': data};
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['error'] ?? e.response!.data['message'] ?? 'Request failed')
          : (e.message ?? 'Network error');
      throw ApiException(msg.toString(), e.response?.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class _AuthInterceptor extends Interceptor {
  final Dio _refresher = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenStore.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  // Token-minting / credential endpoints: a 401 here means bad credentials or a
  // dead refresh token, NOT an expired access token — so don't try to refresh.
  // Everything else (including `/auth/me`, hit on every cold start) is eligible,
  // which is what keeps a session alive across app restarts.
  static bool _isAuthFlow(String p) =>
      p.contains('/auth/login') ||
      p.contains('/auth/register') ||
      p.contains('/auth/google') ||
      p.contains('/auth/guest') ||
      p.contains('/auth/otp') ||
      p.contains('/auth/refresh');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isAuthFlow(err.requestOptions.path)) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final token = await TokenStore.accessToken;
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final clone = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).fetch(opts);
          return handler.resolve(clone);
        } catch (_) {}
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await TokenStore.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await _refresher.post('/auth/refresh', data: {'refreshToken': refresh});
      final data = res.data as Map;
      await TokenStore.save(data['accessToken'], data['refreshToken']);
      return true;
    } catch (_) {
      await TokenStore.clear();
      return false;
    }
  }
}
