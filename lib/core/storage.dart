import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure persistence for auth tokens.
class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _access = 'cc_access';
  static const _refresh = 'cc_refresh';

  static Future<void> save(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  static Future<String?> get accessToken => _storage.read(key: _access);
  static Future<String?> get refreshToken => _storage.read(key: _refresh);
  static Future<void> setAccess(String token) => _storage.write(key: _access, value: token);
  static Future<void> clear() => _storage.deleteAll();
  static Future<bool> get hasSession async => (await accessToken) != null;
}
