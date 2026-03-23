import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000";

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    final response = await http.post(Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> googleLogin(String email, String name) async {
    final response = await http.post(Uri.parse("$baseUrl/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "name": name}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.get(Uri.parse("$baseUrl/profile"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    final response = await http.post(Uri.parse("$baseUrl/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String newPassword) async {
    final response = await http.post(Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "new_password": newPassword}));
    return jsonDecode(response.body);
  }
}
