import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GuardsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<UserModel> guards;
  final String? error;

  const GuardsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.guards = const [],
    this.error,
  });

  GuardsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<UserModel>? guards,
    String? error,
    bool clearError = false,
  }) {
    return GuardsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      guards: guards ?? this.guards,
      error: clearError ? null : (error ?? this.error),
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
      final data = response.data as List<dynamic>;
      final guards = data
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(isLoading: false, guards: guards));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> approveGuard(String guardId, {String notes = ''}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _apiClient.post(
        ApiEndpoints.societyGuardApprove(guardId),
        data: {'notes': notes},
      );
      await loadGuards();
      emit(state.copyWith(isSubmitting: false));
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
      await loadGuards();
      emit(state.copyWith(isSubmitting: false));
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
