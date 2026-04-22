import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/society_detail_screen.dart';
import 'screens/booking_create_screen.dart';
import 'screens/booking_list_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/vehicles_screen.dart';
import 'screens/scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _AuthRefreshNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuth = authState is Authenticated;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookingListScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/societies/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SocietyDetailScreen(
            societyId: id,
            bookingDate: state.uri.queryParameters['bookingDate'],
            startTime: state.uri.queryParameters['startTime'],
            endTime: state.uri.queryParameters['endTime'],
            vehicleType: state.uri.queryParameters['vehicleType'],
          );
        },
      ),
      GoRoute(
        path: '/booking/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final societyId = state.uri.queryParameters['societyId']!;
          final slotId = state.uri.queryParameters['slotId']!;
          return BookingCreateScreen(
            societyId: societyId,
            slotId: slotId,
            bookingDate: state.uri.queryParameters['bookingDate'],
            startTime: state.uri.queryParameters['startTime'],
            endTime: state.uri.queryParameters['endTime'],
          );
        },
      ),
      GoRoute(
        path: '/bookings/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/vehicles',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VehiclesScreen(),
      ),
    ],
  );
}

class _AuthRefreshNotifier extends ChangeNotifier {
  late final AuthBloc _bloc;
  AuthState? _previousState;

  _AuthRefreshNotifier(this._bloc) {
    _bloc.stream.listen((state) {
      if (state != _previousState) {
        _previousState = state;
        notifyListeners();
      }
    });
  }
}
