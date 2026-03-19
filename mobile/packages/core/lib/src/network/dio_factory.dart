import 'package:dio/dio.dart';

import '../auth/bloc/auth_bloc.dart';
import '../auth/token_manager.dart';
import '../config/app_constants.dart';
import '../config/env_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class DioFactory {
  DioFactory._();

  static Dio create({
    required EnvConfig config,
    required TokenManager tokenManager,
    required AuthBloc authBloc,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    final refreshDio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenManager: tokenManager,
        refreshDio: refreshDio,
        authBloc: authBloc,
      ),
      ErrorInterceptor(),
    ]);

    return dio;
  }
}
