import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorageService();
  final tokenManager = TokenManager(storage);

  // Create a bootstrap Dio for AuthService (used before auth is established)
  final bootstrapDio = Dio(BaseOptions(
    baseUrl: EnvConfig.dev.apiBaseUrl,
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    contentType: 'application/json',
  ));

  final authService = AuthService(bootstrapDio, tokenManager);

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

  runApp(AdminApp(
    authBloc: authBloc,
    apiClient: apiClient,
  ));
}

class AdminApp extends StatefulWidget {
  final AuthBloc authBloc;
  final ApiClient apiClient;

  const AdminApp({
    super.key,
    required this.authBloc,
    required this.apiClient,
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
      child: MaterialApp.router(
        title: 'Parking Admin',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
