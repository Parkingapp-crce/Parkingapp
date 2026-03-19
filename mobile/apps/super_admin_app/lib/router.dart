import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'cubits/societies_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/society_list_screen.dart';
import 'screens/society_form_screen.dart';
import 'screens/society_detail_screen.dart';

GoRouter createRouter(AuthBloc authBloc, ApiClient apiClient) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is Unauthenticated || authState is AuthError) {
        return isLoggingIn ? null : '/login';
      }

      if (authState is Authenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return SuperAdminShell(apiClient: apiClient, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/societies',
            builder: (context, state) => const SocietyListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const SocietyFormScreen(),
              ),
              GoRoute(
                path: ':societyId',
                builder: (context, state) {
                  final societyId = state.pathParameters['societyId']!;
                  return SocietyDetailScreen(societyId: societyId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final societyId = state.pathParameters['societyId']!;
                      return SocietyFormScreen(societyId: societyId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class SuperAdminShell extends StatefulWidget {
  final ApiClient apiClient;
  final Widget child;

  const SuperAdminShell({
    super.key,
    required this.apiClient,
    required this.child,
  });

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SocietiesCubit(widget.apiClient),
        ),
      ],
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            switch (index) {
              case 0:
                context.go('/dashboard');
              case 1:
                context.go('/societies');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment),
              label: 'Societies',
            ),
          ],
        ),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
