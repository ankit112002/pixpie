import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String _tokenKey = "token";
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userKey = "user";

  // ===============================
  // 🔐 TOKEN
  // ===============================
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ===============================
  // 👤 USER DATA
  // ===============================
  static Future<void> setUser(String userJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJson);
  }

  static Future<String?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ===============================
  // ✅ LOGIN STATUS
  // ===============================
  static Future<void> setLoginStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
  }

  // ===============================
  // 🚪 LOGOUT (SAFE)
  // ===============================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
  }

  // ===============================
  // 🧹 CLEAR ALL (RARELY NEEDED)
  // ===============================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}