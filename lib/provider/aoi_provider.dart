import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_preferences.dart';
import '../services/api_services.dart';

class AoiProvider extends ChangeNotifier {
  final ApiServices _api = ApiServices();

  bool isLoading = false;
  String? error;
  List<dynamic> myPhotos = [];

  Set<String> _resubmittingIds = {};
  Set<String> _deletingIds = {};

  bool isResubmitting(String id) => _resubmittingIds.contains(id);
  bool isDeleting(String id) => _deletingIds.contains(id);

  String? _currentAoiId; // ✅ store current AOI

  // 🔹 Fetch uploaded photos (WITH AOI ID)
  Future<void> fetchMyUploadedPhotos(String aoiId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await AppPreferences.getToken();

      final uri = Uri.parse(
        "https://pixpe-backend.onrender.com/photos/my-uploads?aoi_id=$aoiId",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        throw jsonDecode(response.body)["message"] ??
            "Failed to fetch photos";
      }

      final data = jsonDecode(response.body);
      myPhotos = data["data"] ?? data; // adjust if needed

    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
  Future<void> uploadPhoto({
    required String filePath,
    required String aoiId,
    required String latitude,
    required String longitude,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      var uri = Uri.parse(
        "https://pixpe-backend.onrender.com/photos/upload",
      );

      var request = http.MultipartRequest("POST", uri);
      final token = await AppPreferences.getToken();


      // If you use token
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['aoi_id'] = aoiId;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['photo_type'] = "front"; // optional

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw jsonDecode(responseData)["message"] ??
            "Upload failed";
      }

    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // 🔹 Resubmit rejected photo
  Future<void> resubmitPhoto(String photoId) async {
    if (_currentAoiId == null) return;

    _resubmittingIds.add(photoId);
    notifyListeners();

    try {
      await _api.resubmitPhoto(photoId);
      await fetchMyUploadedPhotos(_currentAoiId!);
    } catch (e) {
      error = e.toString();
    } finally {
      _resubmittingIds.remove(photoId);
      notifyListeners();
    }
  }

  // 🔹 Delete photo
  Future<void> deletePhoto(String photoId) async {
    _deletingIds.add(photoId);
    notifyListeners();

    try {
      await _api.deletePhoto(photoId);
      myPhotos.removeWhere((p) => p['id'].toString() == photoId);
    } catch (e) {
      error = e.toString();
    } finally {
      _deletingIds.remove(photoId);
      notifyListeners();
    }
  }

  // 🔹 Start AOI
  Future<void> startAoi(String aoiId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _api.startAoi(aoiId);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔹 Submit AOI
  Future<void> submitAoi(String aoiId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    final token = await AppPreferences.getToken();


    try {
      final response = await http.patch(
        Uri.parse(
          "https://pixpe-backend.onrender.com/aoi/$aoiId/submit",
        ),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw jsonDecode(response.body)["message"] ??
            "Failed to submit AOI";
      }

    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}