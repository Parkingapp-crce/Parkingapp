import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  static const String baseUrl = "http://localhost:3000";
  // Emulator → http://10.0.2.2:3000
  // Real device → your IP

  /// 🔹 LOGIN
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 🔹 REGISTER
  static Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    return jsonDecode(response.body);
  }

  /// 🔥 GOOGLE LOGIN (NEW)
  static Future<Map<String, dynamic>> googleLogin(
      String email, String name) async {

    final response = await http.post(
      Uri.parse("$baseUrl/google-login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "name": name,
      }),
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
}