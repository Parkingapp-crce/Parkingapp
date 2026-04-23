import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class GuardCredentialRecord {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final bool canScanEntry;
  final bool canScanExit;
  final String societyName;
  final String createdAt;

  const GuardCredentialRecord({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.canScanEntry,
    required this.canScanExit,
    required this.societyName,
    required this.createdAt,
  });

  factory GuardCredentialRecord.fromJson(Map<String, dynamic> json) {
    return GuardCredentialRecord(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      fullName: json['full_name'] as String,
      canScanEntry: json['can_scan_entry'] as bool? ?? false,
      canScanExit: json['can_scan_exit'] as bool? ?? false,
      societyName: json['society_name'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );
  }
}

class GuardsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<GuardCredentialRecord> guards;
  final String? error;
  final GuardCredentialRecord? latestGuard;
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
    List<GuardCredentialRecord>? guards,
    String? error,
    GuardCredentialRecord? latestGuard,
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
      temporaryPassword: temporaryPassword ?? this.temporaryPassword,
    );
  }
}

class GuardsCubit extends Cubit<GuardsState> {
  final ApiClient _apiClient;

  GuardsCubit(this._apiClient) : super(const GuardsState());

  Future<void> loadGuards() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.guards);
      final data = response.data;
      final guards = <GuardCredentialRecord>[];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        guards.addAll(
          (data['results'] as List)
              .map((item) => GuardCredentialRecord.fromJson(item as Map<String, dynamic>)),
        );
      } else if (data is List) {
        guards.addAll(
          data.map((item) => GuardCredentialRecord.fromJson(item as Map<String, dynamic>)),
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
    emit(state.copyWith(isSubmitting: true, clearError: true, clearLatest: true));
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
      final guard = GuardCredentialRecord.fromJson(
        data['guard'] as Map<String, dynamic>,
      );
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
        data: {
          'can_scan_entry': canScanEntry,
          'can_scan_exit': canScanExit,
        },
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
}