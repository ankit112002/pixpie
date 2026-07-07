import 'package:flutter/material.dart';
import '../services/api_services.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiServices _api = ApiServices();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? get profile => _profile;

  void _handleException(dynamic e) {
    final errorStr = e.toString().replaceAll("Exception: ", "");
    if (errorStr.contains('SocketException') || errorStr.contains('Connection refused')) {
      _error = "Cannot connect to server. Please check your internet or try again later.";
    } else if (errorStr.contains('TimeoutException')) {
      _error = "Connection timed out. Please try again.";
    } else if (errorStr.contains('FormatException')) {
      _error = "Server returned an invalid response. Please try again later.";
    } else {
      _error = errorStr;
    }
  }

  // ==============================
  // 🔹 FETCH PROFILE
  // ==============================
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _api.getUserProfile();
    } catch (e) {
      _handleException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==============================
  // 🔹 UPDATE PROFILE
  // ==============================
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedData = await _api.updateUserProfile(
        name: name,
        email: email,
        phone: phone,
      );
      _profile = updatedData;
    } catch (e) {
      _handleException(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}