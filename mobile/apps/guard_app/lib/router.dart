import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/scan_result_screen.dart';
import 'screens/scan_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/home',
    redirect: (BuildContext context, GoRouterState state) {
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is Authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan/entry',
        builder: (context, state) => const ScanScreen(isEntry: true),
      ),
      GoRoute(
        path: '/scan/exit',
        builder: (context, state) => const ScanScreen(isEntry: false),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final isSuccess = extra['isSuccess'] as bool;
          final data = extra['data'] as Map<String, dynamic>?;
          final errorMessage = extra['errorMessage'] as String?;
          final isEntry = extra['isEntry'] as bool;
          return ScanResultScreen(
            isSuccess: isSuccess,
            data: data,
            errorMessage: errorMessage,
            isEntry: isEntry,
          );
        },
      ),
    ],
  );
}
