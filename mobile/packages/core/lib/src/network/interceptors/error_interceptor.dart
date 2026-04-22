import 'dart:io';

import 'package:dio/dio.dart';

import '../api_exceptions.dart';

String? _extractErrorMessage(dynamic data) {
  if (data is String) {
    final trimmed = data.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  if (data is List) {
    for (final item in data) {
      final message = _extractErrorMessage(item);
      if (message != null) {
        return message;
      }
    }
    return null;
  }

  if (data is Map<String, dynamic>) {
    for (final key in const ['error', 'detail', 'message', 'non_field_errors']) {
      final message = _extractErrorMessage(data[key]);
      if (message != null) {
        return message;
      }
    }

    for (final entry in data.entries) {
      final message = _extractErrorMessage(entry.value);
      if (message != null) {
        return '${entry.key}: $message';
      }
    }
  }

  return null;
}

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
        final message = _extractErrorMessage(data) ?? 'Something went wrong.';

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
