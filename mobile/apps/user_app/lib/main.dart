import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'router.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeNotifier = await ThemeNotifier.create();

  final storage = SecureStorageService();
  final tokenManager = TokenManager(storage);

  final bootstrapDio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.dev.apiBaseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
    ),
  );

  final authService = AuthService(bootstrapDio, tokenManager);

  final authBloc = AuthBloc(
    authService: authService,
    tokenManager: tokenManager,
  );

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
  getIt.registerSingleton<ThemeNotifier>(themeNotifier);

  authBloc.setApiClient(apiClient);
  authBloc.add(const AuthCheckRequested());

  runApp(ParkingApp(authBloc: authBloc, themeNotifier: themeNotifier));
}

class ParkingApp extends StatelessWidget {
  final AuthBloc authBloc;
  final ThemeNotifier themeNotifier;

  const ParkingApp({
    super.key,
    required this.authBloc,
    required this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final router = createRouter(authBloc);

    return BlocProvider.value(
      value: authBloc,
      child: ListenableBuilder(
        listenable: themeNotifier,
        builder: (context, _) => MaterialApp.router(
          title: 'ParkEase',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeNotifier.themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}
