import 'package:flutter/foundation.dart';
import '../../core/api.dart';
import '../../core/campus.dart';
import '../../core/socket.dart';
import '../../core/storage.dart';
import '../../models.dart';

enum AuthState { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthState state = AuthState.unknown;
  AppUser? user;
  String? error;

  Future<void> bootstrap() async {
    if (await TokenStore.hasSession) {
      try {
        final res = await Api.instance.get('/auth/me');
        user = AppUser.fromJson(res['user']);
        await CampusService.applyForUser(user!.universityId);
        state = AuthState.signedIn;
        await SocketService.instance.connect();
      } catch (_) {
        await TokenStore.clear();
        state = AuthState.signedOut;
      }
    } else {
      state = AuthState.signedOut;
    }
    notifyListeners();
  }

  Future<bool> _consume(Future<Map<String, dynamic>> call) async {
    error = null;
    try {
      final res = await call;
      await TokenStore.save(res['accessToken'], res['refreshToken']);
      user = AppUser.fromJson(res['user']);
      await CampusService.applyForUser(user!.universityId);
      state = AuthState.signedIn;
      await SocketService.instance.connect();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) =>
      _consume(Api.instance.post('/auth/login', {'email': email, 'password': password}));

  Future<bool> register(String email, String password, String fullName, {String? universityId}) => _consume(
      Api.instance.post('/auth/register', {
        'email': email, 'password': password, 'fullName': fullName,
        if (universityId != null) 'universityId': universityId,
      }));

  Future<bool> guest() => _consume(Api.instance.post('/auth/guest'));

  Future<void> refreshMe() async {
    try {
      final res = await Api.instance.get('/auth/me');
      user = AppUser.fromJson(res['user']);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> signOut() async {
    final rt = await TokenStore.refreshToken;
    if (rt != null) await Api.instance.post('/auth/logout', {'refreshToken': rt}).catchError((_) => <String, dynamic>{});
    SocketService.instance.disconnect();
    await TokenStore.clear();
    user = null;
    state = AuthState.signedOut;
    notifyListeners();
  }
}
