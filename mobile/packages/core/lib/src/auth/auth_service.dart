import 'package:dio/dio.dart';

import '../models/society_model.dart';
import '../models/user_model.dart';
import '../network/api_exceptions.dart';
import '../network/api_endpoints.dart';
import 'token_manager.dart';

class AuthService {
  final Dio _dio;
  final TokenManager _tokenManager;

  AuthService(this._dio, this._tokenManager);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
    String role = 'user',
    String? societyJoinCode,
    String? flatNumber,
    String? floorNumber,
    String? societyName,
    String? societyAddress,
    String? societyCity,
    String? societyState,
    String? societyPincode,
    double? societyLatitude,
    double? societyLongitude,
  }) async {
    try {
      final data = <String, dynamic>{
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'password': password,
        'role': role,
      };

      if (role == 'user') {
        data['society_join_code'] = societyJoinCode;
        if (flatNumber != null) data['flat_number'] = flatNumber;
        if (floorNumber != null) data['floor_number'] = floorNumber;
      }

      if (role == 'society_admin') {
        data['society_name'] = societyName;
        data['society_address'] = societyAddress;
        data['society_city'] = societyCity;
        data['society_state'] = societyState;
        data['society_pincode'] = societyPincode;
        data['society_latitude'] = societyLatitude?.toStringAsFixed(6);
        data['society_longitude'] = societyLongitude?.toStringAsFixed(6);
      }

      final response = await _dio.post(ApiEndpoints.register, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<SocietyModel>> getPublicSocieties() async {
    final response = await _dio.get(ApiEndpoints.publicSocieties);
    final data = response.data;
    if (data is List) {
      return data
          .map((item) => SocietyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic> && data['results'] is List) {
      return (data['results'] as List)
          .map((item) => SocietyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> applyForGuardAccess({
    required String email,
    required String phone,
    required String fullName,
    required String password,
    required String societyId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.guardRegister,
      data: {
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'password': password,
        'society_id': societyId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getProfile() async {
    try {
      final accessToken = await _tokenManager.getAccessToken();
      final response = await _dio.get(
        ApiEndpoints.profile,
        options: Options(
          headers: accessToken != null
              ? {'Authorization': 'Bearer $accessToken'}
              : null,
        ),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  ApiException _mapDioException(DioException err) {
    String extractMessage(Map<String, dynamic> data) {
      final direct =
          data['error'] ??
          data['detail'] ??
          data['message'] ??
          (data['non_field_errors'] as List?)?.first;
      if (direct is String && direct.trim().isNotEmpty) {
        return direct;
      }

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
        if (value is List && value.isNotEmpty) {
          final first = value.first;
          if (first is String && first.trim().isNotEmpty) {
            return first;
          }
        }
      }

      return 'Something went wrong.';
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;
        String message = 'Something went wrong.';

        if (data is Map<String, dynamic>) {
          message = extractMessage(data);
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      default:
        return ApiException(message: err.message ?? 'Unknown error');
    }
  }
}
