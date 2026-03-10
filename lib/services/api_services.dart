// ==============================
// api_services.dart
// ==============================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_preferences.dart';

class ApiServices {
  // ==============================
  // 🔐 COMMON AUTH HEADER
  // ==============================
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AppPreferences.getToken();
    if (token == null || token.isEmpty) {
      throw SessionExpiredException("Session expired. Please login again.");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==============================
  // 📦 COMMON RESPONSE HANDLER
  // ==============================
  Future<dynamic> _handleResponse(http.Response response) async {
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");

    dynamic body;

    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    } catch (e) {
      body = {"message": response.body};
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    if (response.statusCode == 401) {
      await AppPreferences.logout();
      throw SessionExpiredException();
    }

    throw Exception(body["message"] ?? "Something went wrong");
  }

  // ==============================
  // 📝 ADMIN SIGNUP
  // ==============================
  Future<Map<String, dynamic>> adminSignUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/auth/signup");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    final data = await _handleResponse(response);

    final token = data['accessToken'];
    if (token != null) {
      await AppPreferences.setToken(token);
      await AppPreferences.setLoginStatus(true);
    }

    return data;
  }

  // ==============================
  // 🔑 LOGIN ADMIN
  // ==============================
  Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = await _handleResponse(response);

    final token = data['accessToken'] ?? data['token'] ?? data['access_token'];
    if (token == null || token.isEmpty) {
      throw Exception("Token not found in response");
    }

    await AppPreferences.setToken(token);
    await AppPreferences.setLoginStatus(true);

    if (data['user'] != null) {
      await AppPreferences.setUser(jsonEncode(data['user']));
    }

    return data;
  }

  // ==============================
  // 📍 GET AOI
  // ==============================
  // 📍 GET AOI
  Future<List<dynamic>> getAoi() async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/aoi/assigned");
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    final body = await _handleResponse(response);

    // body is already a List<dynamic>, so return directly
    if (body is List) {
      return body;
    } else {
      throw Exception("Unexpected AOI response format");
    }
  }
  // ==============================
// 📍 GET UNASSIGNED AOI
// ==============================
  Future<List<dynamic>> getUnAssignedAoi() async {
    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/aoi?unassigned=true",
    );

    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    final body = await _handleResponse(response);

    // API returns List directly
    if (body is List) {
      return body;
    } else if (body is Map && body["data"] is List) {
      return body["data"];
    } else {
      throw Exception("Unexpected Unassigned AOI response format");
    }
  }

  // ==============================
// 📍 REQUEST AOI
// ==============================
  Future<void> requestAoi({
    required String aoiId,
    required String requestNotes,
  }) async {

    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/aoi-requests",
    );

    final headers = await _getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "aoi_id": aoiId,
        "request_notes": requestNotes,
      }),
    );

    await _handleResponse(response);
  }


  // ==============================
  // 👤 GET USER PROFILE
  // ==============================
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/users/profile");
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    return await _handleResponse(response);
  }
  // ==============================
// ✏️ UPDATE USER PROFILE
// ==============================
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/users/profile");
    final headers = await _getAuthHeaders();

    // Only include non-null fields
    final body = <String, dynamic>{};
    if (name != null) body["name"] = name;
    if (email != null) body["email"] = email;
    if (phone != null) body["phone"] = phone;

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    return await _handleResponse(response);
  }

  // ==============================
  // ▶ START AOI
  // ==============================
  Future<Map<String, dynamic>> startAoi(String aoiId) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/aoi/$aoiId/start");
    final headers = await _getAuthHeaders();
    final response = await http.patch(url, headers: headers);
    return await _handleResponse(response);
  }

  // ==============================
  // ✅ SUBMIT AOI
  // ==============================
  Future<Map<String, dynamic>> submitAoi(String aoiId) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/aoi/$aoiId/submit");
    final headers = await _getAuthHeaders();
    final response = await http.patch(url, headers: headers);
    return await _handleResponse(response);
  }

  // ==============================
  // 📂 UPLOAD PHOTO
  // ==============================
  // ==============================
// 📸 UPLOAD PHOTO
// ==============================
  Future<void> uploadPhoto({
    required String filePath,
    required String aoiId,
    required String latitude,
    required String longitude,
    required String photoType,
  }) async {

    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/photos/upload",
    );

    final headers = await _getAuthHeaders();

    var request = http.MultipartRequest("POST", url);

    request.headers.addAll(headers);

    request.fields["aoi_id"] = aoiId;
    request.fields["latitude"] = latitude;
    request.fields["longitude"] = longitude;
    request.fields["photo_type"] = photoType;

    request.files.add(
      await http.MultipartFile.fromPath(
        "file",
        filePath,
      ),
    );

    final response = await request.send();
    final responseBody =
    await http.Response.fromStream(response);

    await _handleResponse(responseBody);
  }
  // ==============================
  // 🖼 GET MY UPLOADED PHOTOS
  // ==============================
  // ==============================
// 🖼 GET MY UPLOADED PHOTOS (WITH AOI ID)
// ==============================
  Future<List<dynamic>> getMyUploadedPhotos(String aoiId) async {
    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/photos/my-uploads?aoi_id=$aoiId",
    );

    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    final data = await _handleResponse(response);

    return data["data"] ?? data;
  }

  // ==============================
  // 🔁 RESUBMIT PHOTO
  // ==============================
  Future<Map<String, dynamic>> resubmitPhoto(String photoId) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/photos/$photoId/resubmit");
    final headers = await _getAuthHeaders();
    final response = await http.patch(url, headers: headers);
    return await _handleResponse(response);
  }

  // ==============================
  // 🗑 DELETE PHOTO
  // ==============================
  Future<Map<String, dynamic>> deletePhoto(String photoId) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/photos/$photoId");
    final headers = await _getAuthHeaders();
    final response = await http.delete(url, headers: headers);
    return await _handleResponse(response);
  }
  // ==============================
// 📄 UPLOAD KYC DOCUMENT
// ==============================
  Future<Map<String, dynamic>> uploadKycDocument({
    required String filePath,
    required String type,
  }) async {
    final url = Uri.parse("https://pixpe-backend.onrender.com/surveyor/kyc/upload");

    final headers = await _getAuthHeaders();

    var request = http.MultipartRequest("POST", url);
    request.headers.addAll(headers);

    // Add type field
    request.fields["type"] = type;

    // Add file
    request.files.add(
      await http.MultipartFile.fromPath("file", filePath),
    );

    final response = await request.send();
    final responseBody = await http.Response.fromStream(response);

    return await _handleResponse(responseBody);
  }

  // ==============================
// 🪪 SUBMIT KYC DETAILS
// ==============================
  Future<Map<String, dynamic>> submitKyc({
    required String fullName,
    required String dateOfBirth,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    required String documentType,
    required String documentNumber,
    required String documentFrontUrl,
    required String documentBackUrl,
    required String selfieUrl,
    required String bankAccountNumber,
    required String ifscCode,
    required String bankProofUrl,
  }) async {

    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/surveyor/kyc",
    );

    final headers = await _getAuthHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "full_name": fullName,
        "date_of_birth": dateOfBirth,
        "address": address,
        "city": city,
        "state": state,
        "pin_code": pinCode,
        "document_type": documentType,
        "document_number": documentNumber,
        "document_front_url": documentFrontUrl,
        "document_back_url": documentBackUrl,
        "selfie_url": selfieUrl,
        "bank_account_number": bankAccountNumber,
        "ifsc_code": ifscCode,
        "bank_proof_url": bankProofUrl,
      }),
    );

    return await _handleResponse(response);
  }

  /// ===============================
  /// 📄 GET KYC STATUS
  /// ===============================
  Future<Map<String, dynamic>> getKycStatus() async {

    final url = Uri.parse(
      "https://pixpe-backend.onrender.com/surveyor/kyc/status",
    );

    final headers = await _getAuthHeaders();

    final response = await http.get(url, headers: headers);

    return await _handleResponse(response);
  }
}


// ==============================
// 🔥 SESSION EXCEPTION CLASS
// ==============================
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = "Session expired"]);
  @override
  String toString() => message;
}