import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuardsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<UserModel> guards;
  final String? error;
  final UserModel? latestGuard;
  final String? temporaryPassword;

  const GuardsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.guards = const [],
    this.error,
    this.latestGuard,
    this.temporaryPassword,
  });

  GuardsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<UserModel>? guards,
    String? error,
    UserModel? latestGuard,
    String? temporaryPassword,
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

  GuardsCubit(this._apiClient) : super(const GuardsState());

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
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createGuard({
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
      final guard = UserModel.fromJson(data['guard'] as Map<String, dynamic>);
      final credentials = data['credentials'] as Map<String, dynamic>;

      emit(
        state.copyWith(
          isSubmitting: false,
          latestGuard: guard,
          temporaryPassword: credentials['temporary_password'] as String?,
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
