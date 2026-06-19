import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuardsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<UserModel> guards;
  final String? error;
  final UserModel? latestGuard;
  final String? temporaryPassword;
  final String? savedGuardEmail;
  final String? savedGuardPassword;

  const GuardsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.guards = const [],
    this.error,
    this.latestGuard,
    this.temporaryPassword,
    this.savedGuardEmail,
    this.savedGuardPassword,
  });

  GuardsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<UserModel>? guards,
    String? error,
    UserModel? latestGuard,
    String? temporaryPassword,
    String? savedGuardEmail,
    String? savedGuardPassword,
    bool clearError = false,
    bool clearLatest = false,
  }) {
    return GuardsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      guards: guards ?? this.guards,
      error: clearError ? null : (error ?? this.error),
      latestGuard: clearLatest ? null : (latestGuard ?? this.latestGuard),
      temporaryPassword: clearLatest
          ? null
          : (temporaryPassword ?? this.temporaryPassword),
      savedGuardEmail: savedGuardEmail ?? this.savedGuardEmail,
      savedGuardPassword: savedGuardPassword ?? this.savedGuardPassword,
    );
  }

  List<UserModel> get pendingGuards =>
      guards.where((guard) => guard.approvalStatus == 'pending').toList();

  List<UserModel> get approvedGuards =>
      guards.where((guard) => guard.approvalStatus == 'approved').toList();

  List<UserModel> get rejectedGuards =>
      guards.where((guard) => guard.approvalStatus == 'rejected').toList();
}

class GuardsCubit extends Cubit<GuardsState> {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  GuardsCubit(this._apiClient)
      : _storage = SecureStorageService(),
        super(const GuardsState());

  Future<void> loadSavedGuardCredentials() async {
    final email = await _storage.getGuardEmail();
    final password = await _storage.getGuardPassword();

    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      final legacyEmail = await _storage.getEmail();
      final legacyPassword = await _storage.getPassword();

      if (legacyEmail == null ||
          legacyEmail.isEmpty ||
          legacyPassword == null ||
          legacyPassword.isEmpty) {
        return;
      }

      final looksLikeGuardEmail = legacyEmail.toLowerCase().startsWith('gate-');
      if (!looksLikeGuardEmail) {
        return;
      }

      await _storage.saveGuardCredentials(
        email: legacyEmail,
        password: legacyPassword,
      );
      await _storage.clearCredentials();

      emit(
        state.copyWith(
          savedGuardEmail: legacyEmail,
          savedGuardPassword: legacyPassword,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        savedGuardEmail: email,
        savedGuardPassword: password,
      ),
    );
  }

  Future<void> loadGuards() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.societyGuards);
      final data = response.data;
      final guards = <UserModel>[];

      if (data is Map<String, dynamic> && data['results'] is List) {
        guards.addAll(
          (data['results'] as List).map(
            (item) => UserModel.fromJson(item as Map<String, dynamic>),
          ),
        );
      } else if (data is List) {
        guards.addAll(
          data.map((item) => UserModel.fromJson(item as Map<String, dynamic>)),
        );
      }

      emit(state.copyWith(isLoading: false, guards: guards));

      final hasSavedGuardCredentials =
          (state.savedGuardEmail != null && state.savedGuardPassword != null);
      if (!hasSavedGuardCredentials) {
        final latestGuardWithPassword = guards.firstWhere(
          (guard) =>
              (guard.temporaryPassword != null && guard.temporaryPassword!.isNotEmpty),
          orElse: () => UserModel(
            id: '',
            email: '',
            phone: '',
            fullName: '',
            role: '',
          ),
        );

        if (latestGuardWithPassword.id.isNotEmpty) {
          await _storage.saveGuardCredentials(
            email: latestGuardWithPassword.email,
            password: latestGuardWithPassword.temporaryPassword!,
          );
          emit(
            state.copyWith(
              savedGuardEmail: latestGuardWithPassword.email,
              savedGuardPassword: latestGuardWithPassword.temporaryPassword!,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<Map<String, dynamic>?> createGuard({
    required String fullName,
    required String phone,
    required bool canScanEntry,
    required bool canScanExit,
  }) async {
    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearLatest: true),
    );
    try {
      final response = await _apiClient.post(
        ApiEndpoints.guards,
        data: {
          'full_name': fullName,
          'phone': phone,
          'can_scan_entry': canScanEntry,
          'can_scan_exit': canScanExit,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final deviceJson = (data['device'] as Map<String, dynamic>?) ??
          (data['guard'] as Map<String, dynamic>);
      final guard = UserModel.fromJson(deviceJson);
      final credentials = data['credentials'] as Map<String, dynamic>;
      final password = credentials['temporary_password'] as String;

      await _storage.saveGuardCredentials(email: guard.email, password: password);

      emit(
        state.copyWith(
          isSubmitting: false,
          latestGuard: guard,
          temporaryPassword: password,
          savedGuardEmail: guard.email,
          savedGuardPassword: password,
        ),
      );
      await loadGuards();
      return {'guard': guard, 'device': guard, 'password': password};
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateGuardPermissions({
    required String guardId,
    required bool canScanEntry,
    required bool canScanExit,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiClient.patch(
        ApiEndpoints.guard(guardId),
        data: {'can_scan_entry': canScanEntry, 'can_scan_exit': canScanExit},
      );

      emit(state.copyWith(isSubmitting: false));
      await loadGuards();
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteGuard(String guardId) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiClient.delete(ApiEndpoints.guard(guardId));

      final shouldClearSaved = state.latestGuard?.id == guardId;
      if (shouldClearSaved) {
        await _storage.clearGuardCredentials();
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          clearLatest: shouldClearSaved,
          savedGuardEmail: shouldClearSaved ? null : state.savedGuardEmail,
          savedGuardPassword:
              shouldClearSaved ? null : state.savedGuardPassword,
        ),
      );
      await loadGuards();
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> approveGuard(String guardId, {String notes = ''}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiClient.post(
        ApiEndpoints.societyGuardApprove(guardId),
        data: {'notes': notes},
      );
      emit(state.copyWith(isSubmitting: false));
      await loadGuards();
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }

  Future<void> rejectGuard(String guardId, {String notes = ''}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiClient.post(
        ApiEndpoints.societyGuardReject(guardId),
        data: {'notes': notes},
      );
      emit(state.copyWith(isSubmitting: false));
      await loadGuards();
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
