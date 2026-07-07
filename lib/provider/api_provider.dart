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



  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

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

  /// ===============================
  /// GENERIC POST API
  /// ===============================
  Future<void> post({
    required String url,
    required Map<String, dynamic> body,
    String? token,
  }) async {

    _setLoading(true);
    _error = null;
    _data = null;

    try {

      final headers = {"Content-Type": "application/json"};

      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      debugPrint("API Response Status: ${response.statusCode}");
      debugPrint("API Response Body: ${response.body}");

      if (response.statusCode >= 500) {
        _error = "Server is currently undergoing maintenance. Please try again later.";
        _setLoading(false);
        return;
      }

      final decoded =
      response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {

        _data = decoded;

        if (decoded is Map) {
          final accessToken =
              decoded['accessToken'] ??
                  decoded['access_token'] ??
                  decoded['token'];

          if (accessToken != null && accessToken is String) {
            await AppPreferences.setToken(accessToken);
          }
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
      debugPrint("API POST Error: $e");
      _handleException(e);
    }

    _setLoading(false);
  }

  /// ===============================
  /// ADMIN SIGNUP
  /// ===============================
  Future<void> adminSignUp({
    required String email,
    required String password,
    required String name,
  }) async {

    const url = "https://pixpe.dtcindia.co.in/api/auth/signup";

    await post(
      url: url,
      body: {
        "email": email,
        "password": password,
        "name": name,
      },
    );
  }

  /// ===============================
  /// ADMIN LOGIN
  /// ===============================
  Future<void> loginAdmin({
    required String email,
    required String password,
  }) async {
    const url = "https://pixpe.dtcindia.co.in/api/auth/login";
    await post(
      url: url,
      body: {
        "email": email,
        "password": password,
      },
    );
  }

  /// ===============================
  /// GET ASSIGNED AOI
  /// ===============================
  Future<void> getAoi() async {

    _setLoading(true);
    _error = null;
    _data = null;

    try {

      final token = await AppPreferences.getToken();

      final response = await http.get(
        Uri.parse("https://pixpe.dtcindia.co.in/api/aoi/assigned"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode >= 500) {
        _error = "Server is currently undergoing maintenance. Please try again later.";
        _setLoading(false);
        return;
      }

      if (response.statusCode == 200) {

        final decoded =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

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
      _handleException(e);
    }

    _setLoading(false);
  }

  /// ===============================
  /// GET UNASSIGNED AOI
  /// ===============================
  Future<void> getUnAssignedAoi() async {

    _setLoading(true);
    _error = null;

    try {

      final result = await _apiServices.getUnAssignedAoi();
      _unassignedAoi = result;

    } on SessionExpiredException catch (e) {

      _error = e.toString();

    } catch (e) {

      _handleException(e);

    }

    _setLoading(false);
  }

  /// ===============================
  /// REQUEST AOI
  /// ===============================
  Future<bool> requestAoi({
    required String aoiId,
    required String requestNotes,
  }) async {

    _setLoading(true);
    _error = null;

    try {

      await _apiServices.requestAoi(
        aoiId: aoiId,
        requestNotes: requestNotes,
      );

      _requestedAoiIds.add(aoiId);

      return true;

    } catch (e) {

      _handleException(e);
      return false;

    }

    finally {
      _setLoading(false);
    }
  }
  /// ===============================
  /// KYC UPLOAD STATE
  /// ===============================
  List<String> _uploadedKycUrls = [];
  List<String> get uploadedKycUrls => _uploadedKycUrls;
  /// ===============================
  /// 📄 UPLOAD KYC DOCUMENT
  /// ===============================
  /// ===============================
  /// 📄 UPLOAD KYC DOCUMENT
  /// ===============================
  Future<void> uploadKycDocument({
    required String filePath,
    required String type,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiServices.uploadKycDocument(
        filePath: filePath,
        type: type,
      );

      // response contains {"url": "..."}
      if (response["url"] != null) {
        _uploadedKycUrls.add(response["url"]);
      }

    } catch (e) {
      _handleException(e);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// ===============================
  /// 🪪 SUBMIT KYC
  /// ===============================
  Future<bool> submitKyc({
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
    _setLoading(true);
    _error = null; // Clear previous errors

    try {
      final response = await _apiServices.submitKyc(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        documentType: documentType,
        documentNumber: documentNumber,
        documentFrontUrl: documentFrontUrl,
        documentBackUrl: documentBackUrl,
        selfieUrl: selfieUrl,
        bankAccountNumber: bankAccountNumber,
        ifscCode: ifscCode,
        bankProofUrl: bankProofUrl,
      );

      _data = response;
      return true;
    } catch (e) {
      debugPrint("KYC Submit Error: $e");
      _handleException(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  /// ===============================
  /// KYC STATUS DATA
  /// ===============================
  String? _kycStatus;
  String? _rejectionReason;

  String? get kycStatus => _kycStatus;
  String? get rejectionReason => _rejectionReason;

  String? _submittedAt;
  String? get submittedAt => _submittedAt;

  /// ===============================
  /// GET KYC STATUS
  /// ===============================
  Future<void> fetchKycStatus() async {

    _setLoading(true);
    _error = null;

    try {

      final response = await _apiServices.getKycStatus();

      _kycStatus = response["status"];
      _submittedAt = response["submitted_at"];
      _rejectionReason = response["rejection_reason"];

    } catch (e) {

      _handleException(e);

    } finally {

      _setLoading(false);
      notifyListeners();

    }
  }
}