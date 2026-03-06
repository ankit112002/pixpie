import 'package:shared_preferences/shared_preferences.dart';

class SessionController {
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _tokenKey = "token";

  /// Save login session
  static Future<void> saveSession(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_tokenKey, token);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get saved token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Logout user
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}