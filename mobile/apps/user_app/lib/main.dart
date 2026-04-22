import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:get_it/get_it.dart';

import 'router.dart';

final getIt = GetIt.instance;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final tokenManager = TokenManager(storage);

  // Bootstrap Dio for AuthService (used before auth is established)
  final bootstrapDio = Dio(BaseOptions(
    baseUrl: EnvConfig.dev.apiBaseUrl,
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    contentType: 'application/json',
  ));

  final authService = AuthService(bootstrapDio);

  final authBloc = AuthBloc(
    authService: authService,
    tokenManager: tokenManager,
  );

  // Create the authenticated Dio with interceptors
  final dio = DioFactory.create(
    config: EnvConfig.dev,
    tokenManager: tokenManager,
    authBloc: authBloc,
  );

  final apiClient = ApiClient(dio);

  if (getIt.isRegistered<ApiClient>()) {
    getIt.unregister<ApiClient>();
  }
  getIt.registerSingleton<ApiClient>(apiClient);

  // Now set the apiClient on authBloc
  authBloc.setApiClient(apiClient);

  // Check existing auth state
  authBloc.add(const AuthCheckRequested());

  runApp(ParkingApp(authBloc: authBloc));
}

class ParkingApp extends StatelessWidget {
  final AuthBloc authBloc;

  const ParkingApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    final router = createRouter(authBloc);

    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp.router(
        title: 'ParkEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
