import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'cubits/slots_cubit.dart';
import 'cubits/bookings_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/slot_list_screen.dart';
import 'screens/slot_form_screen.dart';
import 'screens/slot_detail_screen.dart';
import 'screens/booking_list_screen.dart';

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
          return AdminShell(apiClient: apiClient, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/slots',
            builder: (context, state) => const SlotListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const SlotFormScreen(),
              ),
              GoRoute(
                path: ':slotId',
                builder: (context, state) {
                  final slotId = state.pathParameters['slotId']!;
                  return SlotDetailScreen(slotId: slotId);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final slotId = state.pathParameters['slotId']!;
                      return SlotFormScreen(slotId: slotId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingListScreen(),
          ),
        ],
      ),
    ],
  );
}

class AdminShell extends StatefulWidget {
  final ApiClient apiClient;
  final Widget child;

  const AdminShell({
    super.key,
    required this.apiClient,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SlotsCubit(widget.apiClient),
        ),
        BlocProvider(
          create: (_) => BookingsCubit(widget.apiClient),
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
                context.go('/slots');
              case 2:
                context.go('/bookings');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_parking_outlined),
              selectedIcon: Icon(Icons.local_parking),
              label: 'Slots',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_online_outlined),
              selectedIcon: Icon(Icons.book_online),
              label: 'Bookings',
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
