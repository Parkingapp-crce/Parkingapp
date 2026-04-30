import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  // Web: http://localhost:8000
  // Emulator: http://10.0.2.2:8000
  // Real device: your PC IP e.g. http://192.168.0.103:8000

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Map<String, dynamic> _decodeMapBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {"data": decoded};
  }

  /// ðŸ”¹ LOGIN (all roles)
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ REGISTER (Customer)
  static Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ REGISTER OWNER
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
        "parking_name": lotName,   // âœ… Fixed: Django expects parking_name
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

  /// ðŸ”¥ GOOGLE LOGIN
  static Future<Map<String, dynamic>> googleLogin(
      String email, String name) async {
    final response = await http.post(
      Uri.parse("$baseUrl/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "name": name}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ PROFILE
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ OWNER DASHBOARD
  static Future<Map<String, dynamic>> getOwnerDashboard() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/owner/dashboard"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ ADMIN DASHBOARD
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

  /// ðŸ”¹ GET ALL PARKING LOTS (for customers)
  static Future<Map<String, dynamic>> getParkingLots() async {
    final response = await http.get(
      Uri.parse("$baseUrl/parking-lots"),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ FORGOT PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ VERIFY OTP
  static Future<Map<String, dynamic>> verifyOTP(
      String email, String otp) async {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ RESET PASSWORD
  static Future<Map<String, dynamic>> resetPassword(
      String email, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "new_password": newPassword}),
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ BOOK SLOT
  static Future<Map<String, dynamic>> bookSlot({
    required int parkingLotId,
    required String vehicleNumber,
    required String vehicleType,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _getToken();

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/book-slot"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "parking_lot_id": parkingLotId,
              "vehicle_number": vehicleNumber,
              "vehicle_type": vehicleType,
              "start_time": startTime,
              "end_time": endTime,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final body = _decodeMapBody(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      }

      return {
        ...body,
        "status_code": response.statusCode,
        "error": body["error"] ??
            body["detail"] ??
            body["message"] ??
            "Booking failed.",
      };
    } on TimeoutException {
      return {
        "error": "Request timed out. Check that the backend is running.",
      };
    } on FormatException {
      return {
        "error":
            "The server returned an unexpected response. Check the backend logs.",
      };
    } on http.ClientException {
      return {
        "error":
            "Cannot reach the server. Verify the API URL and backend server.",
      };
    }
  }

  /// ðŸ”¹ MY BOOKINGS
  static Future<List<dynamic>> getMyBookings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/my-bookings"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ GET QR CODE
  static Future<Map<String, dynamic>> getBookingQR(int bookingId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/booking/$bookingId/qr-image"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    return jsonDecode(response.body);
  }

  /// ðŸ”¹ CANCEL BOOKING
  static Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/cancel-booking"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"booking_id": bookingId}),
    );
    return jsonDecode(response.body);
  }
}
