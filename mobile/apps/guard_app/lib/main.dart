import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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

  // We need a late-initialized AuthBloc for DioFactory, so we create Dio manually
  // and then register AuthBloc with it.

  // Using a factory approach to break the circular dependency:

  // 1. Create a bare Dio for AuthService (login doesn't need auth interceptor initially)
  final baseDio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.dev.apiBaseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
    ),
  );

  // Auth Service (uses base dio for login, profile will use intercepted dio)
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(baseDio),
  );

  // Auth Bloc
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authService: getIt<AuthService>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  // Authenticated Dio (with interceptors)
  getIt.registerLazySingleton<Dio>(
    () => DioFactory.create(
      config: EnvConfig.dev,
      tokenManager: getIt<TokenManager>(),
      authBloc: getIt<AuthBloc>(),
    ),
  );

  // ApiClient (uses authenticated Dio)
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<Dio>()),
  );

  // ✅ Wire ApiClient into AuthBloc so profile requests use the authenticated Dio
  getIt<AuthBloc>().setApiClient(getIt<ApiClient>());
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();
  runApp(const GuardApp());
}

class GuardApp extends StatefulWidget {
  const GuardApp({super.key});

  @override
  State<GuardApp> createState() => _GuardAppState();
}

class _GuardAppState extends State<GuardApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
    getIt<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Guard App',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}