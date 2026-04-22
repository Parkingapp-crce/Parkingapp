import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://192.168.0.105:8000"; // same as owner app

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

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

  /// 🔹 VALIDATE QR (guard scans)
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

  /// 🔹 LOGOUT (clear local session)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}