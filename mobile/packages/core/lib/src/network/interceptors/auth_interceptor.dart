import 'package:dio/dio.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/token_manager.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final TokenManager _tokenManager;
  final Dio _refreshDio;
  final AuthBloc _authBloc;

  AuthInterceptor({
    required TokenManager tokenManager,
    required Dio refreshDio,
    required AuthBloc authBloc,
  })  : _tokenManager = tokenManager,
        _refreshDio = refreshDio,
        _authBloc = authBloc;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        await _tokenManager.clearTokens();
        _authBloc.add(const AuthLoggedOut());
        return handler.reject(err);
      }

      final response = await _refreshDio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      final newAccess = response.data['access'] as String;
      final newRefresh =
          (response.data['refresh'] as String?) ?? refreshToken;

      await _tokenManager.saveTokens(
        access: newAccess,
        refresh: newRefresh,
      );

      // Retry original request with new token
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _refreshDio.fetch(retryOptions);
      return handler.resolve(retryResponse);
    } catch (_) {
      await _tokenManager.clearTokens();
      _authBloc.add(const AuthLoggedOut());
      return handler.reject(err);
    }
  }
}
