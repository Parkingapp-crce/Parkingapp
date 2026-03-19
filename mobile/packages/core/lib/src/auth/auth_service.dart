import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../network/api_endpoints.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
