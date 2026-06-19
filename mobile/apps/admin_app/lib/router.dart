import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'cubits/bookings_cubit.dart';
import 'cubits/dashboard_cubit.dart';
import 'cubits/guards_cubit.dart';
import 'cubits/slots_cubit.dart';
import 'screens/booking_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guards_screen.dart';
import 'screens/join_requests_screen.dart';
import 'screens/login_screen.dart';
import 'screens/owner_detail_screen.dart';
import 'screens/owners_screen.dart';
import 'screens/register_screen.dart';
import 'screens/slot_detail_screen.dart';
import 'screens/slot_form_screen.dart';
import 'screens/slot_list_screen.dart';

GoRouter createRouter(AuthBloc authBloc, ApiClient apiClient) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isPublicAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is Unauthenticated || authState is AuthError) {
        return isPublicAuthRoute ? null : '/login';
      }

      if (authState is Authenticated && isPublicAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => RepositoryProvider.value(
          value: apiClient,
          child: const RegisterScreen(),
        ),
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
            path: '/guards',
            builder: (context, state) => const GuardsScreen(),
          ),
          GoRoute(
            path: '/join-requests',
            builder: (context, state) => const JoinRequestsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => NotificationInboxScreen(
              apiClient: apiClient,
              title: 'Notifications',
            ),
          ),
          GoRoute(
            path: '/owners',
            builder: (context, state) => const OwnersScreen(),
            routes: [
              GoRoute(
                path: ':ownerId',
                builder: (context, state) {
                  final ownerId = state.pathParameters['ownerId']!;
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return OwnerDetailScreen(
                    ownerId: ownerId,
                    ownerName: extra['name'] as String? ?? 'Owner',
                    ownerEmail: extra['email'] as String? ?? '',
                    ownerPhone: extra['phone'] as String? ?? '',
                  );
                },
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

  const AdminShell({super.key, required this.apiClient, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = switch (location) {
      final path when path.startsWith('/slots') => 1,
      final path when path.startsWith('/guards') => 2,
      final path when path.startsWith('/owners') => 3,
      final path when path.startsWith('/bookings') => 4,
      _ => 0,
    };

    return RepositoryProvider.value(
      value: widget.apiClient,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SlotsCubit(widget.apiClient)),
          BlocProvider(create: (_) => BookingsCubit(widget.apiClient)),
          BlocProvider(create: (_) => DashboardCubit(widget.apiClient)),
          BlocProvider(create: (_) => GuardsCubit(widget.apiClient)),
        ],
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: widget.child,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                  case 1:
                    context.go('/slots');
                  case 2:
                    context.go('/guards');
                  case 3:
                    context.go('/owners');
                  case 4:
                    context.go('/bookings');
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_parking_outlined),
                  selectedIcon: Icon(Icons.local_parking_rounded),
                  label: 'Slots',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shield_outlined),
                  selectedIcon: Icon(Icons.shield_rounded),
                  label: 'Guards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: 'Owners',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Bookings',
                ),
              ],
            ),
          ),
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
