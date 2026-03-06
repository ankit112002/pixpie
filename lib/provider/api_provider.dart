import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../app_preferences.dart';
import '../services/api_services.dart';

final ApiServices _apiServices = ApiServices();

class ApiProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  dynamic _data;
  dynamic get data => _data;

  List<dynamic> _unassignedAoi = [];
  List<dynamic> get unassignedAoi => _unassignedAoi;

  Set<String> _requestedAoiIds = {};
  Set<String> get requestedAoiIds => _requestedAoiIds;


  /// Generic API call method
  Future<void> post({
    required String url,
    required Map<String, dynamic> body,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    _data = null;
    notifyListeners();

    try {
      final headers = {"Content-Type": "application/json"};
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _data = decoded;

        // ✅ FIXED TOKEN EXTRACTION
        final accessToken =
            decoded['accessToken'] ??
                decoded['access_token'] ??
                decoded['token'];

        if (accessToken != null && accessToken is String) {
          await AppPreferences.setToken(accessToken);
        }
      } else {
        if (decoded is Map && decoded["message"] != null) {
          if (decoded["message"] is List) {
            _error = (decoded["message"] as List).join(", ");
          } else {
            _error = decoded["message"].toString();
          }
        } else {
          _error = "Request failed (${response.statusCode})";
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convenience method for Admin SignUp
  Future<void> adminSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    const url = "https://pixpe-backend.onrender.com/auth/signup";
    await post(url: url, body: {
      "email": email,
      "password": password,
      "name": name,
    });
  }
  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _data = null;
    notifyListeners();

    const url = "https://pixpe-backend.onrender.com/auth/login";

    print("🔵 LOGIN API CALLED");
    print("📩 Email: $email");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("🟢 LOGIN STATUS CODE: ${response.statusCode}");
      print("🟢 LOGIN RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        print("🔍 FULL RESPONSE DATA: $responseData");

        /// 🔐 Extract token (check all possible keys)
        final token = responseData['accessToken'] ??
            responseData['token'] ??
            responseData['access_token'];

        print("🔐 EXTRACTED TOKEN: $token");

        if (token == null || token.isEmpty) {
          print("❌ TOKEN NOT FOUND IN RESPONSE");
          _error = "Token not found in response";
        } else {
          await AppPreferences.setToken(token);
          print("✅ TOKEN SAVED SUCCESSFULLY");

          final savedToken = await AppPreferences.getToken();
          print("📦 VERIFY SAVED TOKEN: $savedToken");

          _data = responseData;
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)["message"] ?? "Login failed";
        print("❌ LOGIN FAILED: $errorMsg");
        _error = errorMsg;
      }
    } catch (e) {
      print("🔥 LOGIN EXCEPTION: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> getAoi() async {
    _isLoading = true;
    _error = null;
    _data = null;
    notifyListeners();

    try {
      final token = await AppPreferences.getToken();

      final response = await http.get(
        Uri.parse("https://pixpe-backend.onrender.com/aoi/assigned"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("🟢 AOI STATUS CODE: ${response.statusCode}");
      print("🟢 AOI RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        print("🔍 DECODED TYPE: ${decoded.runtimeType}");

        // ✅ HANDLE DIFFERENT RESPONSE STRUCTURES SAFELY
        if (decoded is List) {
          _data = decoded;
        } else if (decoded is Map && decoded["data"] is List) {
          _data = decoded["data"];
        } else {
          _data = [];
        }
      } else {
        _error = "Failed to fetch AOI";
      }
    } catch (e) {
      print("🔥 AOI EXCEPTION: $e");
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // ==============================
// GET UNASSIGNED AOI
// ==============================
  Future<void> getUnAssignedAoi() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiServices.getUnAssignedAoi();
      _unassignedAoi = result;
    } on SessionExpiredException catch (e) {
      _error = e.toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==============================
// REQUEST AOI
// ==============================
  Future<bool> requestAoi({
    required String aoiId,
    required String requestNotes,
  }) async {

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiServices.requestAoi(
        aoiId: aoiId,
        requestNotes: requestNotes,
      );

      _requestedAoiIds.add(aoiId);   // ✅ mark as requested
      return true;

    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // ==============================
// UPLOAD PHOTO
// ==============================
//   Future<bool> uploadPhoto({
//     required String filePath,
//     required String aoiId,
//     required String latitude,
//     required String longitude,
//     required String photoType,
//   }) async {
//
//     _isLoading = true;
//     _error = null;
//     notifyListeners();
//
//     try {
//       await _apiServices.uploadPhoto(
//         filePath: filePath,
//         aoiId: aoiId,
//         latitude: latitude,
//         longitude: longitude,
//         photoType: photoType,
//       );
//
//       return true;
//     } catch (e) {
//       _error = e.toString();
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

  // Future<void> uploadPhoto({
  //   required String filePath,
  //   required String aoiId,
  //   required String photoType,
  //   required String latitude,
  //   required String longitude,
  // }) async {
  //   _isLoading = true;
  //   _error = null;
  //   _data = null;
  //   notifyListeners();
  //
  //   try {
  //     final token = await AppPreferences.getToken();
  //
  //     var request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse("https://pixpe-backend.onrender.com/photos/upload"),
  //     );
  //
  //     // 🔐 Add Authorization Header
  //     if (token != null) {
  //       request.headers['Authorization'] = 'Bearer $token';
  //     }
  //
  //     // 📂 Add File
  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         'file',
  //         filePath,
  //       ),
  //     );
  //
  //     // 📝 Add Other Fields
  //     request.fields['aoi_id'] = aoiId;
  //     request.fields['photo_type'] = photoType;
  //     request.fields['latitude'] = latitude;
  //     request.fields['longitude'] = longitude;
  //
  //     print("📤 UPLOAD REQUEST SENT");
  //
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     print("🟢 UPLOAD STATUS: ${response.statusCode}");
  //     print("🟢 UPLOAD RESPONSE: ${response.body}");
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       _data = jsonDecode(response.body);
  //     } else {
  //       _error =
  //           jsonDecode(response.body)['message'] ?? "Photo upload failed";
  //     }
  //   } catch (e) {
  //     print("🔥 UPLOAD ERROR: $e");
  //     _error = e.toString();
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
}