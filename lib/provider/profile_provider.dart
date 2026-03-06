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
      _error = e.toString();
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
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}