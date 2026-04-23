import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://localhost:8000";
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000";
    }
    return "http://localhost:8000";
  }
  // Web: http://localhost:8000
  // Emulator: http://10.0.2.2:8000
  // Real device: your PC IP e.g. http://192.168.1.5:8000

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// 🔹 LOGIN (all roles)
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/auth/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 REGISTER (Customer)
  static Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 REGISTER OWNER
  static Future<Map<String, dynamic>> registerOwner({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String flatNumber,
    required String floorNumber,
    required String joinCode,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/auth/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "flat_number": flatNumber,
        "floor_number": floorNumber,
        "role": "user",
        "society_join_code": joinCode,
      }),
    );
    return jsonDecode(response.body);
  }

  /// 🔥 GOOGLE LOGIN
  static Future<Map<String, dynamic>> googleLogin(
      String email, String name) async {
    final response = await http.post(
      Uri.parse("$baseUrl/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "name": name}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/auth/profile/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// 🔹 GET MY SLOTS
  static Future<List<dynamic>> getMySlots(String societyId, String ownerId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/v1/societies/$societyId/slots/?owner_id=$ownerId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        return data['results'] as List<dynamic>;
      } else if (data is List) {
        return data;
      }
    }
    return [];
  }

  /// 🔹 ADD SLOT
  static Future<Map<String, dynamic>> addSlot({
    required String societyId,
    required String slotNumber,
    required String floor,
    required String slotType,
    required double hourlyRate,
    required String availableFrom,
    required String availableTo,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/api/v1/societies/$societyId/slots/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "slot_number": slotNumber,
        "floor": floor,
        "slot_type": slotType,
        "hourly_rate": hourlyRate,
        "available_from_write": availableFrom,
        "available_to_write": availableTo,
      }),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 ADMIN DASHBOARD
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/admin/dashboard"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// 🔹 GET ALL PARKING LOTS (for customers)
  static Future<Map<String, dynamic>> getParkingLots() async {
    final response = await http.get(
      Uri.parse("$baseUrl/parking-lots"),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  /// 🔹 FORGOT PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 VERIFY OTP
  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 RESET PASSWORD
  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "new_password": newPassword}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 VALIDATE QR (owner scans)
  static Future<Map<String, dynamic>> validateQR(String code) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/validate-qr"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"code": code}),
    );
    return jsonDecode(response.body);
  }

  /// 🔹 ENTRY LOGS
  static Future<List<dynamic>> getEntryLogs() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/owner/entry-logs"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }
}
