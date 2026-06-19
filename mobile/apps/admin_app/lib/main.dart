import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'router.dart';

Future<void> main() async {
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
  authBloc.setApiClient(apiClient);

  if (!GetIt.I.isRegistered<ThemeNotifier>()) {
    GetIt.I.registerSingleton<ThemeNotifier>(themeNotifier);
  }

  runApp(AdminApp(
      authBloc: authBloc, apiClient: apiClient, themeNotifier: themeNotifier));
}

class AdminApp extends StatefulWidget {
  final AuthBloc authBloc;
  final ApiClient apiClient;
  final ThemeNotifier themeNotifier;

  const AdminApp({
    super.key,
    required this.authBloc,
    required this.apiClient,
    required this.themeNotifier,
  });

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authBloc, widget.apiClient);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.authBloc,
      child: ListenableBuilder(
        listenable: widget.themeNotifier,
        builder: (context, _) => MaterialApp.router(
          title: 'Parking Admin',
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
