import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/admin_dashboard_model.dart';

class DashboardState {
  final bool isLoading;
  final AdminDashboardModel? dashboard;
  final String? error;

  const DashboardState({this.isLoading = false, this.dashboard, this.error});

  DashboardState copyWith({
    bool? isLoading,
    AdminDashboardModel? dashboard,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      dashboard: dashboard ?? this.dashboard,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  final ApiClient _apiClient;

  DashboardCubit(this._apiClient) : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.societyAdminDashboard);
      final data = response.data as Map<String, dynamic>;
      emit(
        state.copyWith(
          isLoading: false,
          dashboard: AdminDashboardModel.fromJson(data),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
