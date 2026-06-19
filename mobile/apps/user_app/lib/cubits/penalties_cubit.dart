import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

class PenaltiesState {
  final bool isLoading;
  final List<PenaltyModel> penalties;
  final String? error;

  const PenaltiesState({
    this.isLoading = false,
    this.penalties = const [],
    this.error,
  });

  PenaltiesState copyWith({
    bool? isLoading,
    List<PenaltyModel>? penalties,
    String? error,
  }) {
    return PenaltiesState(
      isLoading: isLoading ?? this.isLoading,
      penalties: penalties ?? this.penalties,
      error: error,
    );
  }

  /// Returns unpaid penalties for a given booking ID.
  List<PenaltyModel> unpaidFor(String bookingId) =>
      penalties.where((p) => p.booking == bookingId && p.isUnpaid).toList();
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class PenaltiesCubit extends Cubit<PenaltiesState> {
  final ApiClient _apiClient;

  PenaltiesCubit(this._apiClient) : super(const PenaltiesState());

  /// Load all penalties for the current user (optionally filter by status).
  Future<void> load({String? status}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final queryParams = status != null ? '?status=$status' : '';
      final response = await _apiClient.get(
        '${ApiEndpoints.penalties}$queryParams',
      );
      final data = response.data;
      List<PenaltyModel> results = [];

      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final list = data['results'] as List<dynamic>;
        results = list
            .map((e) => PenaltyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        results = data
            .map((e) => PenaltyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      emit(state.copyWith(isLoading: false, penalties: results));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Initiate penalty payment — returns the PaymentModel or null on failure.
  Future<PaymentModel?> payPenalty(
    String penaltyId, {
    bool embedded = false,
    String gateway = 'stripe',
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.penaltyPay(penaltyId),
        data: {
          'gateway': gateway,
          'embedded': embedded,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return PaymentModel.fromJson(data);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
      return null;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return null;
    }
  }
}
