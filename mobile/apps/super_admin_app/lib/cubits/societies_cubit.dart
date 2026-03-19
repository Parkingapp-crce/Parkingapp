import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SocietiesState {
  final bool isLoading;
  final List<SocietyModel> societies;
  final String? error;
  final String searchQuery;
  final Map<String, dynamic>? dashboardData;
  final bool isDashboardLoading;

  const SocietiesState({
    this.isLoading = false,
    this.societies = const [],
    this.error,
    this.searchQuery = '',
    this.dashboardData,
    this.isDashboardLoading = false,
  });

  SocietiesState copyWith({
    bool? isLoading,
    List<SocietyModel>? societies,
    String? error,
    String? searchQuery,
    Map<String, dynamic>? dashboardData,
    bool? isDashboardLoading,
    bool clearError = false,
  }) {
    return SocietiesState(
      isLoading: isLoading ?? this.isLoading,
      societies: societies ?? this.societies,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      dashboardData: dashboardData ?? this.dashboardData,
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
    );
  }

  List<SocietyModel> get filteredSocieties {
    if (searchQuery.isEmpty) return societies;
    final query = searchQuery.toLowerCase();
    return societies.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();
  }
}

class SocietiesCubit extends Cubit<SocietiesState> {
  final ApiClient _apiClient;

  SocietiesCubit(this._apiClient) : super(const SocietiesState());

  Future<void> loadSocieties() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.societies);
      final data = response.data;
      List<SocietyModel> societies;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final apiResponse = ApiResponse<SocietyModel>.fromJson(
          data,
          (json) => SocietyModel.fromJson(json),
        );
        societies = apiResponse.results;
      } else if (data is List) {
        societies = data
            .map((e) => SocietyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        societies = [];
      }
      emit(state.copyWith(isLoading: false, societies: societies));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> loadDashboard() async {
    emit(state.copyWith(isDashboardLoading: true, clearError: true));
    try {
      final response = await _apiClient.get(ApiEndpoints.adminDashboard);
      final data = response.data as Map<String, dynamic>;
      emit(state.copyWith(isDashboardLoading: false, dashboardData: data));
    } on ApiException catch (e) {
      emit(state.copyWith(isDashboardLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isDashboardLoading: false, error: e.toString()));
    }
  }

  Future<void> createSociety(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiClient.post(ApiEndpoints.societies, data: data);
      await loadSocieties();
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateSociety(String id, Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _apiClient.put(ApiEndpoints.society(id), data: data);
      await loadSocieties();
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      rethrow;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> toggleSocietyActive(String id, bool isActive) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.society(id),
        data: {'is_active': isActive},
      );
      await loadSocieties();
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<Map<String, dynamic>?> loadSocietyStats(String societyId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.adminSocietyStats(societyId),
      );
      return response.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  SocietyModel? getSocietyById(String id) {
    try {
      return state.societies.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
