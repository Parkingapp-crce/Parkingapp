import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';

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

  // Auth Bloc - register early so DioFactory can use it
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authService: getIt<AuthService>(),
      tokenManager: getIt<TokenManager>(),
    ),
  );

  // Dio
  getIt.registerLazySingleton<AuthService>(() {
    final dio = DioFactory.create(
      config: EnvConfig.dev,
      tokenManager: getIt<TokenManager>(),
      authBloc: getIt<AuthBloc>(),
    );
    return AuthService(dio);
  });

  // ApiClient
  getIt.registerLazySingleton<ApiClient>(() {
    final dio = DioFactory.create(
      config: EnvConfig.dev,
      tokenManager: getIt<TokenManager>(),
      authBloc: getIt<AuthBloc>(),
    );
    return ApiClient(dio);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _setupDependencies();

  final authBloc = getIt<AuthBloc>();
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
