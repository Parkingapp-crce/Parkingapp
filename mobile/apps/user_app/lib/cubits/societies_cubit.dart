import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SocietySearchRequest {
  final LocationSuggestionModel destination;
  final LocationSuggestionModel? currentLocation;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String vehicleType;

  const SocietySearchRequest({
    required this.destination,
    this.currentLocation,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.vehicleType,
  });

  Map<String, dynamic> toRequestBody() {
    return {
      'destination_text': destination.label,
      'destination_lat': destination.latitude,
      'destination_lng': destination.longitude,
      if (destination.placeId.isNotEmpty)
        'destination_place_id': destination.placeId,
      if (currentLocation != null) 'current_lat': currentLocation!.latitude,
      if (currentLocation != null) 'current_lng': currentLocation!.longitude,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'vehicle_type': vehicleType,
    };
  }
}

class SocietiesState {
  final bool isLoading;
  final bool isLoadingSuggestions;
  final bool isResolvingLocation;
  final List<SocietySearchResultModel> results;
  final List<LocationSuggestionModel> destinationSuggestions;
  final LocationSuggestionModel? selectedDestination;
  final LocationSuggestionModel? currentLocation;
  final String? error;
  final bool hasSearched;
  final SocietySearchRequest? lastRequest;
  final String? resolvedDestinationLabel;
  final double? searchRadiusKm;

  const SocietiesState({
    this.isLoading = false,
    this.isLoadingSuggestions = false,
    this.isResolvingLocation = false,
    this.results = const [],
    this.destinationSuggestions = const [],
    this.selectedDestination,
    this.currentLocation,
    this.error,
    this.hasSearched = false,
    this.lastRequest,
    this.resolvedDestinationLabel,
    this.searchRadiusKm,
  });

  SocietiesState copyWith({
    bool? isLoading,
    bool? isLoadingSuggestions,
    bool? isResolvingLocation,
    List<SocietySearchResultModel>? results,
    List<LocationSuggestionModel>? destinationSuggestions,
    LocationSuggestionModel? selectedDestination,
    LocationSuggestionModel? currentLocation,
    String? error,
    bool? hasSearched,
    SocietySearchRequest? lastRequest,
    String? resolvedDestinationLabel,
    double? searchRadiusKm,
    bool clearError = false,
    bool clearSuggestions = false,
    bool clearSelectedDestination = false,
    bool clearCurrentLocation = false,
  }) {
    return SocietiesState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      results: results ?? this.results,
      destinationSuggestions: clearSuggestions
          ? const []
          : (destinationSuggestions ?? this.destinationSuggestions),
      selectedDestination: clearSelectedDestination
          ? null
          : (selectedDestination ?? this.selectedDestination),
      currentLocation: clearCurrentLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      error: clearError ? null : (error ?? this.error),
      hasSearched: hasSearched ?? this.hasSearched,
      lastRequest: lastRequest ?? this.lastRequest,
      resolvedDestinationLabel:
          resolvedDestinationLabel ?? this.resolvedDestinationLabel,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    );
  }
}

class SocietiesCubit extends Cubit<SocietiesState> {
  final ApiClient _apiClient;

  SocietiesCubit(this._apiClient) : super(const SocietiesState());

  Future<void> loadDestinationSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      emit(state.copyWith(isLoadingSuggestions: false, clearSuggestions: true));
      return;
    }

    emit(state.copyWith(isLoadingSuggestions: true, clearError: true));

    try {
      final response = await _apiClient.get(
        ApiEndpoints.destinationAutocomplete,
        queryParameters: {'q': trimmed},
      );
      final payload = response.data as Map<String, dynamic>;
      final rawResults = payload['results'] as List<dynamic>? ?? const [];
      final suggestions = rawResults
          .map(
            (item) =>
                LocationSuggestionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          destinationSuggestions: suggestions,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          clearSuggestions: true,
          error: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingSuggestions: false,
          clearSuggestions: true,
          error: e.toString(),
        ),
      );
    }
  }

  void selectDestination(LocationSuggestionModel destination) {
    emit(
      state.copyWith(
        selectedDestination: destination,
        clearSuggestions: true,
        clearError: true,
      ),
    );
  }

  void clearDestinationSelection() {
    emit(
      state.copyWith(clearSelectedDestination: true, clearSuggestions: true),
    );
  }

  Future<LocationSuggestionModel?> reverseGeocode({
    required double latitude,
    required double longitude,
    bool setAsDestination = false,
    bool setAsCurrentLocation = false,
  }) async {
    emit(state.copyWith(isResolvingLocation: true, clearError: true));

    try {
      final response = await _apiClient.get(
        ApiEndpoints.destinationReverseGeocode,
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      final location = LocationSuggestionModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      emit(
        state.copyWith(
          isResolvingLocation: false,
          selectedDestination: setAsDestination ? location : null,
          currentLocation: setAsCurrentLocation ? location : null,
          clearError: true,
        ),
      );
      return location;
    } on ApiException catch (e) {
      emit(state.copyWith(isResolvingLocation: false, error: e.message));
      return null;
    } catch (e) {
      emit(state.copyWith(isResolvingLocation: false, error: e.toString()));
      return null;
    }
  }

  void setCurrentLocation(LocationSuggestionModel location) {
    emit(state.copyWith(currentLocation: location, clearError: true));
  }

  Future<void> searchAvailability(SocietySearchRequest request) async {
    emit(
      state.copyWith(
        isLoading: true,
        hasSearched: true,
        lastRequest: request,
        clearError: true,
      ),
    );

    try {
      final response = await _apiClient.post(
        ApiEndpoints.societySearch,
        data: request.toRequestBody(),
      );
      final searchResponse = SocietySearchResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      emit(
        state.copyWith(
          isLoading: false,
          results: searchResponse.results,
          selectedDestination: request.destination,
          currentLocation: request.currentLocation,
          resolvedDestinationLabel: searchResponse.destination.label,
          searchRadiusKm: searchResponse.searchRadiusKm,
          clearError: true,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(isLoading: false, results: const [], error: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          results: const [],
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    final request = state.lastRequest;
    if (request == null) {
      return;
    }
    await searchAvailability(request);
  }
}
