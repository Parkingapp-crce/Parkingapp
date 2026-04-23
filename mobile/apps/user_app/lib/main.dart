import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';

import 'router.dart';

final getIt = GetIt.instance;

void _setupDependencies() {
  // Storage
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  // Token Manager
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
  );

  // Bootstrap Dio for AuthService (login/register don't need auth interceptor)
  final bootstrapDio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.dev.apiBaseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
    ),
  );

  // Auth Service
  getIt.registerLazySingleton<AuthService>(() {
    return AuthService(bootstrapDio, getIt<TokenManager>());
  });

  // Auth Bloc
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authService: getIt<AuthService>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  // ApiClient (authenticated Dio)
  getIt.registerLazySingleton<ApiClient>(() {
    final authDio = DioFactory.create(
      config: EnvConfig.dev,
      tokenManager: getIt<TokenManager>(),
      authBloc: getIt<AuthBloc>(),
    );
    return ApiClient(authDio);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();

  await getIt<TokenManager>().clearTokens();

  runApp(ParkingApp(authBloc: getIt<AuthBloc>()));
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
