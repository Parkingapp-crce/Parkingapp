import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

final getIt = GetIt.instance;

void _setupDependencies() {
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  getIt.registerLazySingleton<TokenManager>(
    () => TokenManager(getIt<SecureStorageService>()),
  );

  final baseDio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.dev.apiBaseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      contentType: 'application/json',
    ),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthService(baseDio, getIt<TokenManager>()),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authService: getIt<AuthService>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  getIt.registerLazySingleton<Dio>(
    () => DioFactory.create(
      config: EnvConfig.dev,
      tokenManager: getIt<TokenManager>(),
      authBloc: getIt<AuthBloc>(),
    ),
  );

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));
  getIt<AuthBloc>().setApiClient(getIt<ApiClient>());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();

  final themeNotifier = await ThemeNotifier.create();
  getIt.registerSingleton<ThemeNotifier>(themeNotifier);

  await getIt<TokenManager>().clearTokens();
  runApp(GuardApp(themeNotifier: themeNotifier));
}

class GuardApp extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const GuardApp({super.key, required this.themeNotifier});

  @override
  State<GuardApp> createState() => _GuardAppState();
}

class _GuardAppState extends State<GuardApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      child: ListenableBuilder(
        listenable: widget.themeNotifier,
        builder: (context, _) => MaterialApp.router(
          title: 'Gate App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: widget.themeNotifier.themeMode,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
