import 'package:dio/dio.dart';
import 'package:video_face_detecting_app/core/prefernces.dart';
import 'config.dart';

class DioClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    headers: {
      "Content-Type": "application/json",
      "x-candidate-id": AppConfig.candidateId,
    },
  ));

  static Dio get instance => _dio;

  static Future initAuth() async {
    final token = await Prefs.getToken();
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  static setToken(String token) {
    _dio.options.headers["Authorization"] = "Bearer $token";
  }
}
