import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class RefundState {
  final bool isLookingUp;
  final Map<String, dynamic>? lookupData; // booking snapshot from API
  final String? lookupError;

  final bool isSubmitting;
  final Map<String, dynamic>? lastRefund; // most recently created refund
  final String? submitError;

  final bool isLoadingHistory;
  final List<dynamic> history;
  final String? historyError;

  const RefundState({
    this.isLookingUp = false,
    this.lookupData,
    this.lookupError,
    this.isSubmitting = false,
    this.lastRefund,
    this.submitError,
    this.isLoadingHistory = false,
    this.history = const [],
    this.historyError,
  });

  RefundState copyWith({
    bool? isLookingUp,
    Map<String, dynamic>? lookupData,
    String? lookupError,
    bool clearLookup = false,
    bool? isSubmitting,
    Map<String, dynamic>? lastRefund,
    String? submitError,
    bool clearSubmitError = false,
    bool? isLoadingHistory,
    List<dynamic>? history,
    String? historyError,
  }) {
    return RefundState(
      isLookingUp: isLookingUp ?? this.isLookingUp,
      lookupData: clearLookup ? null : (lookupData ?? this.lookupData),
      lookupError: clearLookup ? null : (lookupError ?? this.lookupError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastRefund: lastRefund ?? this.lastRefund,
      submitError:
          clearSubmitError ? null : (submitError ?? this.submitError),
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      history: history ?? this.history,
      historyError: historyError ?? this.historyError,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────────────────────

class RefundCubit extends Cubit<RefundState> {
  final ApiClient _apiClient;

  RefundCubit(this._apiClient) : super(const RefundState());

  // ── Lookup ──────────────────────────────────────────────────────────────────

  Future<void> lookupBooking(String bookingId) async {
    final trimmed = bookingId.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(isLookingUp: true, clearLookup: true));
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminRefundLookup,
        queryParameters: {'booking_id': trimmed},
      );
      emit(
        state.copyWith(
          isLookingUp: false,
          lookupData: response.data as Map<String, dynamic>,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLookingUp: false, lookupError: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLookingUp: false,
          lookupError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void clearLookup() => emit(state.copyWith(clearLookup: true));

  // ── Initiate refund ─────────────────────────────────────────────────────────

  Future<bool> initiateRefund({
    required String bookingId,
    required double refundAmount,
    required String reason,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final response = await _apiClient.post(
        ApiEndpoints.adminRefunds,
        data: {
          'booking_id': bookingId,
          'refund_amount': refundAmount,
          'reason': reason,
        },
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          lastRefund: response.data as Map<String, dynamic>,
          clearLookup: true,
        ),
      );
      // Refresh history after a successful refund
      loadHistory();
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.message));
      return false;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          submitError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  // ── History ─────────────────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoadingHistory: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.adminRefunds);
      final data = response.data;
      final list = data is List ? data : <dynamic>[];
      emit(state.copyWith(isLoadingHistory: false, history: list));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoadingHistory: false, historyError: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingHistory: false,
          historyError: e.toString(),
        ),
      );
    }
  }
}
