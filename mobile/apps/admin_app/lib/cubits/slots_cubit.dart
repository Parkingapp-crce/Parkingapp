import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SlotsState {
  final bool isLoading;
  final List<SlotModel> slots;
  final String? error;
  final String? stateFilter;
  final String? typeFilter;

  const SlotsState({
    this.isLoading = false,
    this.slots = const [],
    this.error,
    this.stateFilter,
    this.typeFilter,
  });

  SlotsState copyWith({
    bool? isLoading,
    List<SlotModel>? slots,
    String? error,
    String? stateFilter,
    String? typeFilter,
    bool clearError = false,
    bool clearStateFilter = false,
    bool clearTypeFilter = false,
  }) {
    return SlotsState(
      isLoading: isLoading ?? this.isLoading,
      slots: slots ?? this.slots,
      error: clearError ? null : (error ?? this.error),
      stateFilter: clearStateFilter ? null : (stateFilter ?? this.stateFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
    );
  }

  List<SlotModel> get filteredSlots {
    var result = slots;
    if (stateFilter != null) {
      if (stateFilter == 'pending') {
        result = result.where((s) => s.approvalStatus == 'pending').toList();
      } else {
        result = result.where((s) => s.state == stateFilter).toList();
      }
    }
    if (typeFilter != null) {
      result = result.where((s) => s.slotType == typeFilter).toList();
    }
    return result;
  }

  int get totalCount => slots.length;
  int get availableCount => slots.where((s) => s.state == 'available').length;
  int get reservedCount => slots.where((s) => s.state == 'reserved').length;
  int get occupiedCount => slots.where((s) => s.state == 'occupied').length;
  int get blockedCount => slots.where((s) => s.state == 'blocked').length;
}

class SlotsCubit extends Cubit<SlotsState> {
  final ApiClient _apiClient;

  SlotsCubit(this._apiClient) : super(const SlotsState());

  Future<void> loadSlots(String societyId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(
        ApiEndpoints.societySlots(societyId),
      );
      final data = response.data;
      List<SlotModel> slots;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final apiResponse = ApiResponse<SlotModel>.fromJson(
          data,
          (json) => SlotModel.fromJson(json),
        );
        slots = apiResponse.results;
      } else if (data is List) {
        slots = data
            .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        slots = [];
      }
      emit(state.copyWith(isLoading: false, slots: slots));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createSlot(String societyId, Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiClient.post(
        ApiEndpoints.societySlots(societyId),
        data: data,
      );
      await loadSlots(societyId);
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateSlot(
    String societyId,
    String slotId,
    Map<String, dynamic> data,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiClient.put(
        ApiEndpoints.slot(societyId, slotId),
        data: data,
      );
      await loadSlots(societyId);
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> blockSlot(String societyId, String slotId) async {
    try {
      await _apiClient.post(ApiEndpoints.slotBlock(societyId, slotId));
      await loadSlots(societyId);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> unblockSlot(String societyId, String slotId) async {
    try {
      await _apiClient.post(ApiEndpoints.slotUnblock(societyId, slotId));
      await loadSlots(societyId);
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> decideSlotApproval(
    String societyId,
    String slotId, {
    required bool approve,
    String notes = '',
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiClient.post(
        ApiEndpoints.slotDecision(societyId, slotId),
        data: {
          'action': approve ? 'approve' : 'reject',
          'notes': notes,
        },
      );
      await loadSlots(societyId);
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  void setStateFilter(String? filter) {
    if (filter == null) {
      emit(state.copyWith(clearStateFilter: true));
    } else {
      emit(state.copyWith(stateFilter: filter));
    }
  }

  void setTypeFilter(String? filter) {
    if (filter == null) {
      emit(state.copyWith(clearTypeFilter: true));
    } else {
      emit(state.copyWith(typeFilter: filter));
    }
  }

  SlotModel? getSlotById(String slotId) {
    try {
      return state.slots.firstWhere((s) => s.id == slotId);
    } catch (_) {
      return null;
    }
  }
}
