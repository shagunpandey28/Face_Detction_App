import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const _tokenKey = 'auth_token';

  static Future<void> setToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
  }
}
