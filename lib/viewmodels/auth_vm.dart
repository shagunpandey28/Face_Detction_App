
import 'package:riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

import '../core/dio_client.dart';
import '../core/prefernces.dart';
import '../models/user_model.dart';
import '../services/auth_services.dart';

final authVMProvider = StateNotifierProvider<AuthVM, AsyncValue<UserModel?>>((ref) {
  return AuthVM();
});

class AuthVM extends StateNotifier<AsyncValue<UserModel?>> {
  final _service = AuthService();
  AuthVM(): super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final token = await Prefs.getToken();
    if (token != null) {
      DioClient.setToken(token);
      try {
        final profile = await _service.fetchProfile();
        state = AsyncValue.data(profile);
      } catch (e) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final token = await _service.login(email, password);
      DioClient.setToken(token);
      final profile = await _service.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(String email, String password, String name) async {
    await _service.register(email, password, name);
  }

  Future<void> logout() async {
    await Prefs.clearToken();
    state = const AsyncValue.data(null);
  }
}
