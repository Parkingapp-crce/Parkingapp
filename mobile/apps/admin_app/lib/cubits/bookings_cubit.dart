import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class BookingsState {
  final bool isLoading;
  final List<BookingModel> bookings;
  final String? error;

  const BookingsState({
    this.isLoading = false,
    this.bookings = const [],
    this.error,
  });

  BookingsState copyWith({
    bool? isLoading,
    List<BookingModel>? bookings,
    String? error,
    bool clearError = false,
  }) {
    return BookingsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BookingsCubit extends Cubit<BookingsState> {
  final ApiClient _apiClient;

  BookingsCubit(this._apiClient) : super(const BookingsState());

  Future<void> loadBookings({String? societyId}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final queryParams = <String, dynamic>{};
      if (societyId != null) {
        queryParams['society'] = societyId;
      }
      final response = await _apiClient.get(
        ApiEndpoints.bookingsList,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      List<BookingModel> bookings;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final apiResponse = ApiResponse<BookingModel>.fromJson(
          data,
          (json) => BookingModel.fromJson(json),
        );
        bookings = apiResponse.results;
      } else if (data is List) {
        bookings = data
            .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        bookings = [];
      }
      emit(state.copyWith(isLoading: false, bookings: bookings));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
