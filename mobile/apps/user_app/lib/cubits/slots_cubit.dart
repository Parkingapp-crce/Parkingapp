import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SlotsState {
  final bool isLoading;
  final SocietyModel? society;
  final List<SlotModel> slots;
  final String? error;
  final String? filterType;
  final String? filterState;
  final String? bookingDate;
  final String? startTime;
  final String? endTime;
  final String? vehicleType;

  const SlotsState({
    this.isLoading = false,
    this.society,
    this.slots = const [],
    this.error,
    this.filterType,
    this.filterState,
    this.bookingDate,
    this.startTime,
    this.endTime,
    this.vehicleType,
  });

  bool get hasAvailabilityContext =>
      bookingDate != null &&
      startTime != null &&
      endTime != null &&
      vehicleType != null;

  SlotsState copyWith({
    bool? isLoading,
    SocietyModel? society,
    List<SlotModel>? slots,
    String? error,
    String? filterType,
    String? filterState,
    String? bookingDate,
    String? startTime,
    String? endTime,
    String? vehicleType,
    bool clearFilterType = false,
    bool clearFilterState = false,
    bool clearError = false,
  }) {
    return SlotsState(
      isLoading: isLoading ?? this.isLoading,
      society: society ?? this.society,
      slots: slots ?? this.slots,
      error: clearError ? null : (error ?? this.error),
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterState: clearFilterState ? null : (filterState ?? this.filterState),
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      vehicleType: vehicleType ?? this.vehicleType,
    );
  }

  List<SlotModel> get filteredSlots {
    if (hasAvailabilityContext) {
      return slots;
    }

    return slots.where((slot) {
      if (filterType != null && slot.slotType != filterType) {
        return false;
      }
      if (filterState != null && slot.state != filterState) {
        return false;
      }
      return true;
    }).toList();
  }
}

class SlotsCubit extends Cubit<SlotsState> {
  final ApiClient _apiClient;

  SlotsCubit(this._apiClient) : super(const SlotsState());

  Future<void> loadSocietyDetail(
    String societyId, {
    String? bookingDate,
    String? startTime,
    String? endTime,
    String? vehicleType,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final societyResponse = await _apiClient.get(
        ApiEndpoints.society(societyId),
      );
      final society = SocietyModel.fromJson(
        societyResponse.data as Map<String, dynamic>,
      );

      final queryParameters = <String, dynamic>{};
      final hasAvailabilityContext =
          bookingDate != null &&
          startTime != null &&
          endTime != null &&
          vehicleType != null;

      if (hasAvailabilityContext) {
        queryParameters.addAll({
          'booking_date': bookingDate,
          'start_time': startTime,
          'end_time': endTime,
          'vehicle_type': vehicleType,
        });
      }

      final slotsResponse = await _apiClient.get(
        ApiEndpoints.societySlots(societyId),
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      final data = slotsResponse.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<SlotModel>.fromJson(
        data,
        (json) => SlotModel.fromJson(json),
      );

      emit(
        state.copyWith(
          isLoading: false,
          society: society,
          slots: apiResponse.results,
          bookingDate: bookingDate,
          startTime: startTime,
          endTime: endTime,
          vehicleType: vehicleType,
          clearFilterType: hasAvailabilityContext,
          clearFilterState: hasAvailabilityContext,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setFilterType(String? type) {
    if (type == null) {
      emit(state.copyWith(clearFilterType: true));
    } else {
      emit(state.copyWith(filterType: type));
    }
  }

  void setFilterState(String? slotState) {
    if (slotState == null) {
      emit(state.copyWith(clearFilterState: true));
    } else {
      emit(state.copyWith(filterState: slotState));
    }
  }
}
