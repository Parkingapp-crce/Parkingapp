import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SocietiesState {
  final bool isLoading;
  final List<SocietyModel> societies;
  final String? error;
  final String searchQuery;

  const SocietiesState({
    this.isLoading = false,
    this.societies = const [],
    this.error,
    this.searchQuery = '',
  });

  SocietiesState copyWith({
    bool? isLoading,
    List<SocietyModel>? societies,
    String? error,
    String? searchQuery,
  }) {
    return SocietiesState(
      isLoading: isLoading ?? this.isLoading,
      societies: societies ?? this.societies,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<SocietyModel> get filteredSocieties {
    if (searchQuery.isEmpty) return societies;
    final query = searchQuery.toLowerCase();
    return societies.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query);
    }).toList();
  }
}

class SocietiesCubit extends Cubit<SocietiesState> {
  final ApiClient _apiClient;

  SocietiesCubit(this._apiClient) : super(const SocietiesState());

  Future<void> loadSocieties() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final response = await _apiClient.get(ApiEndpoints.societies);
      final data = response.data as Map<String, dynamic>;
      final apiResponse = ApiResponse<SocietyModel>.fromJson(
        data,
        (json) => SocietyModel.fromJson(json),
      );
      emit(state.copyWith(isLoading: false, societies: apiResponse.results));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
