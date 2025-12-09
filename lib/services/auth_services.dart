import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../core/prefernces.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = DioClient.instance;

  Future<String> login(String email, String password) async {
    final r = await _dio.post('/auth/login', data: {
      "email": email,
      "password": password,
    });
    final token = r.data['token'] as String;
    await Prefs.setToken(token);
    DioClient.setToken(token);
    return token;
  }

  Future<void> register(String email, String password, String name) async {
    await _dio.post('/auth/register', data: {
      "email": email,
      "password": password,
      "name": name,
    });
  }

  Future<UserModel> fetchProfile() async {
    final r = await _dio.get('/user/profile');
    return UserModel.fromJson(r.data);
  }
}
