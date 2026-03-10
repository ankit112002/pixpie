import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_preferences.dart';
import '../services/api_services.dart';
import 'api_provider.dart';

class AoiProvider extends ChangeNotifier {
  final ApiServices _api = ApiServices();

  // 🔹 Loading flags
  bool isFetchingPhotos = false; // for fetchMyUploadedPhotos
  bool isUploadingPhoto = false; // for uploadPhoto
  bool isStartingAoi = false;
  bool isSubmittingAoi = false;
  bool isLoading=false;

  String? error;
  List<dynamic> myPhotos = [];

  Set<String> _resubmittingIds = {};
  Set<String> _deletingIds = {};

  String? _currentAoiId; // current AOI for uploads/fetching

  bool isResubmitting(String id) => _resubmittingIds.contains(id);
  bool isDeleting(String id) => _deletingIds.contains(id);

  // ===============================
  // Fetch uploaded photos
  // ===============================
  Future<void> uploadPhoto({
    required String filePath,
    required String aoiId,
    required String latitude,
    required String longitude,
  }) async {
    _currentAoiId = aoiId;
    isUploadingPhoto = true;
    error = null;
    notifyListeners();

    try {
      var uri = Uri.parse("https://pixpe-backend.onrender.com/photos/upload");
      var request = http.MultipartRequest("POST", uri);
      final token = await AppPreferences.getToken();

      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      request.fields['aoi_id'] = aoiId;
      request.fields['latitude'] = latitude;
      request.fields['longitude'] = longitude;
      request.fields['photo_type'] = "front";

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      debugPrint("Upload response raw: $responseData");

      dynamic decoded;
      try {
        decoded = jsonDecode(responseData);
      } catch (e) {
        debugPrint("Upload response is not JSON, fallback to raw string: $e");
        decoded = responseData;
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (decoded is Map && decoded.containsKey("message")) {
          throw decoded["message"];
        } else {
          throw "Upload failed: $decoded";
        }
      }

      // ✅ Refresh photos safely
      if (_currentAoiId != null) {
        await fetchMyUploadedPhotos(_currentAoiId!);
      }
    } catch (e) {
      error = e.toString();
      debugPrint("Upload failed safely: $error");
    } finally {
      isUploadingPhoto = false;
      notifyListeners();
    }
  }

// ===============================
// Safe fetchMyUploadedPhotos
// ===============================
  Future<void> fetchMyUploadedPhotos(String aoiId) async {
    _currentAoiId = aoiId;
    isFetchingPhotos = true;
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

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint("fetchMyUploadedPhotos response is not JSON: $e");
        data = response.body;
      }

      // Safe assignment
      if (data is Map && data.containsKey("data")) {
        myPhotos = data["data"] is List ? data["data"] : [];
      } else if (data is List) {
        myPhotos = data;
      } else {
        debugPrint("Unexpected photo data type: ${data.runtimeType}");
        myPhotos = [];
      }

      debugPrint("Fetched myPhotos safely: ${myPhotos.length}");
    } catch (e) {
      error = e.toString();
    } finally {
      isFetchingPhotos = false;
      notifyListeners();
    }
  }
  // ===============================
  // Resubmit rejected photo
  // ===============================
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

  // ===============================
  // Delete photo
  // ===============================
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

  // ===============================
  // Start AOI
  // ===============================
  Future<void> startAoi(String aoiId, ApiProvider apiProvider) async {
    isStartingAoi = true;
    notifyListeners();

    try {
      await _api.startAoi(aoiId);
      await apiProvider.getAoi();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isStartingAoi = false;
      notifyListeners();
    }
  }

  // ===============================
  // Submit AOI
  // ===============================
  Future<void> submitAoi(String aoiId) async {
    isSubmittingAoi = true;
    error = null;
    notifyListeners();

    final token = await AppPreferences.getToken();

    try {
      final response = await http.patch(
        Uri.parse("https://pixpe-backend.onrender.com/aoi/$aoiId/submit"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw jsonDecode(response.body)["message"] ?? "Failed to submit AOI";
      }

    } catch (e) {
      error = e.toString();
    } finally {
      isSubmittingAoi = false;
      notifyListeners();
    }
  }
}