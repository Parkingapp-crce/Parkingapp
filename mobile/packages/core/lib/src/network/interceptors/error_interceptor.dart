import 'dart:io';

import 'package:dio/dio.dart';

import '../api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  String _extractMessage(Map<String, dynamic> data) {
    final direct = data['error'] ??
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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        throw const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;
        String message = 'Something went wrong.';

        if (data is Map<String, dynamic>) {
          message = _extractMessage(data);
        }

        throw ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      default:
        if (err.error is SocketException) {
          throw const NetworkException();
        }
        throw ApiException(message: err.message ?? 'Unknown error');
    }
  }
}
