import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  // Web: http://localhost:8000
  // Emulator: http://10.0.2.2:8000
  // Real device: your PC IP e.g. http://192.168.1.5:8000

  /// 🔹 LOGIN
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
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
    required String lotName,
    required String address,
    required String city,
    required int totalSlots,
    required double pricePerHour,
    required String openingTime,
    required String closingTime,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register-owner"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "lot_name": lotName,
        "address": address,
        "city": city,
        "total_slots": totalSlots,
        "price_per_hour": pricePerHour,
        "opening_time": openingTime,
        "closing_time": closingTime,
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
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
}
