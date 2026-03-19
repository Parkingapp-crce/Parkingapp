import 'dart:io';

import 'package:dio/dio.dart';

import '../api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
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
          message = data['error'] ??
              data['detail'] ??
              data['message'] ??
              (data['non_field_errors'] as List?)?.first ??
              message;
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
