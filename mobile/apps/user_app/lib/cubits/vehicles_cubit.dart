import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class VehiclesState {
  final bool isLoading;
  final List<VehicleModel> vehicles;
  final String? error;
  final bool isAdding;
  final bool isDeleting;
  final bool addSuccess;

  const VehiclesState({
    this.isLoading = false,
    this.vehicles = const [],
    this.error,
    this.isAdding = false,
    this.isDeleting = false,
    this.addSuccess = false,
  });

  VehiclesState copyWith({
    bool? isLoading,
    List<VehicleModel>? vehicles,
    String? error,
    bool? isAdding,
    bool? isDeleting,
    bool? addSuccess,
  }) {
    return VehiclesState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      error: error,
      isAdding: isAdding ?? this.isAdding,
      isDeleting: isDeleting ?? this.isDeleting,
      addSuccess: addSuccess ?? false,
    );
  }
}

class VehiclesCubit extends Cubit<VehiclesState> {
  final ApiClient _apiClient;

  VehiclesCubit(this._apiClient) : super(const VehiclesState());

  Future<void> loadVehicles() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _apiClient.get(ApiEndpoints.vehicles);
      List<VehicleModel> vehicles = [];
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final apiResp = ApiResponse<VehicleModel>.fromJson(
          data,
          (json) => VehicleModel.fromJson(json),
        );
        vehicles = apiResp.results;
      } else if (data is List) {
        vehicles = data
            .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      emit(state.copyWith(isLoading: false, vehicles: vehicles));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<bool> addVehicle({
    required String vehicleType,
    required String registrationNo,
    required String makeModel,
  }) async {
    emit(state.copyWith(isAdding: true, error: null, addSuccess: false));
    try {
      final normalizedRegistration = registrationNo
          .trim()
          .toUpperCase()
          .replaceAll(' ', '');

      await _apiClient
          .post(
        ApiEndpoints.vehicles,
        data: {
          'vehicle_type': vehicleType,
          'registration_no': normalizedRegistration,
          'make_model': makeModel,
        },
      )
          .timeout(const Duration(seconds: 20));
      emit(state.copyWith(isAdding: false, addSuccess: true));
      unawaited(loadVehicles());
      return true;
    } on TimeoutException {
      emit(
        state.copyWith(
          isAdding: false,
          error: 'Request timed out. Please try again.',
          addSuccess: false,
        ),
      );
      return false;
    } on ApiException catch (e) {
      emit(state.copyWith(isAdding: false, error: e.message, addSuccess: false));
      return false;
    } catch (e) {
      emit(state.copyWith(isAdding: false, error: e.toString(), addSuccess: false));
      return false;
    }
  }

  Future<void> deleteVehicle(String id) async {
    emit(state.copyWith(isDeleting: true, error: null));
    try {
      await _apiClient.delete(ApiEndpoints.vehicleDelete(id));
      await loadVehicles();
      emit(state.copyWith(isDeleting: false));
    } on ApiException catch (e) {
      emit(state.copyWith(isDeleting: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isDeleting: false, error: e.toString()));
    }
  }
}
