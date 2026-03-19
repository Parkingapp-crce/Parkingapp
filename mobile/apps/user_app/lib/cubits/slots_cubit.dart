import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SlotsState {
  final bool isLoading;
  final SocietyModel? society;
  final List<SlotModel> slots;
  final String? error;
  final String? filterType;
  final String? filterState;

  const SlotsState({
    this.isLoading = false,
    this.society,
    this.slots = const [],
    this.error,
    this.filterType,
    this.filterState,
  });

  SlotsState copyWith({
    bool? isLoading,
    SocietyModel? society,
    List<SlotModel>? slots,
    String? error,
    String? filterType,
    String? filterState,
    bool clearFilterType = false,
    bool clearFilterState = false,
  }) {
    return SlotsState(
      isLoading: isLoading ?? this.isLoading,
      society: society ?? this.society,
      slots: slots ?? this.slots,
      error: error,
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      filterState: clearFilterState ? null : (filterState ?? this.filterState),
    );
  }

  List<SlotModel> get filteredSlots {
    return slots.where((s) {
      if (filterType != null && s.slotType != filterType) return false;
      if (filterState != null && s.state != filterState) return false;
      return true;
    }).toList();
  }
}

class SlotsCubit extends Cubit<SlotsState> {
  final ApiClient _apiClient;

  SlotsCubit(this._apiClient) : super(const SlotsState());

  Future<void> loadSocietyDetail(String societyId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final societyResponse = await _apiClient.get(
        ApiEndpoints.society(societyId),
      );
      final society = SocietyModel.fromJson(
        societyResponse.data as Map<String, dynamic>,
      );

      final slotsResponse = await _apiClient.get(
        ApiEndpoints.societySlots(societyId),
      );
      final data = slotsResponse.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<SlotModel>.fromJson(
        data,
        (json) => SlotModel.fromJson(json),
      );

      emit(state.copyWith(
        isLoading: false,
        society: society,
        slots: apiResponse.results,
      ));
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
