import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/user_model.dart';
import '../../network/api_exceptions.dart';
import '../auth_service.dart';
import '../token_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final TokenManager _tokenManager;

  AuthBloc({
    required AuthService authService,
    required TokenManager tokenManager,
  })  : _authService = authService,
        _tokenManager = tokenManager,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLoggedOut>(_onLoggedOut);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasTokens = await _tokenManager.hasTokens();
    if (!hasTokens) {
      emit(const Unauthenticated());
      return;
    }

    try {
      final user = await _authService.getProfile();
      emit(Authenticated(user));
    } catch (_) {
      await _tokenManager.clearTokens();
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final data = await _authService.login(
        email: event.email,
        password: event.password,
      );

      final access = data['access'] as String;
      final refresh = data['refresh'] as String;
      await _tokenManager.saveTokens(access: access, refresh: refresh);

      final user = await _authService.getProfile();
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final data = await _authService.register(
        email: event.email,
        phone: event.phone,
        fullName: event.fullName,
        password: event.password,
        role: event.role,
        societyJoinCode: event.societyJoinCode,
        societyName: event.societyName,
        societyAddress: event.societyAddress,
        societyCity: event.societyCity,
        societyState: event.societyState,
        societyPincode: event.societyPincode,
        societyLatitude: event.societyLatitude,
        societyLongitude: event.societyLongitude,
      );

      final tokens = data['tokens'] as Map<String, dynamic>;
      await _tokenManager.saveTokens(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      emit(Authenticated(user));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenManager.clearTokens();
    emit(const Unauthenticated());
  }
}
