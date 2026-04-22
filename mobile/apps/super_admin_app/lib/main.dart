import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'router.dart';

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
  
  // Now set the apiClient on authBloc
  authBloc.setApiClient(apiClient);

  // Check existing auth state
  authBloc.add(const AuthCheckRequested());

  runApp(SuperAdminApp(
    authBloc: authBloc,
    apiClient: apiClient,
  ));
}

class SuperAdminApp extends StatefulWidget {
  final AuthBloc authBloc;
  final ApiClient apiClient;

  const SuperAdminApp({
    super.key,
    required this.authBloc,
    required this.apiClient,
  });

  @override
  State<SuperAdminApp> createState() => _SuperAdminAppState();
}

class _SuperAdminAppState extends State<SuperAdminApp> {
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
        title: 'Parking Super Admin',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
