import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';

class SlotPin {
  final SocietyModel society;
  final SlotModel slot;
  final double latitude;
  final double longitude;
  final double? distanceKm;

  const SlotPin({
    required this.society,
    required this.slot,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
  });

  int? get walkingMinutes {
    if (distanceKm == null) return null;
    return (distanceKm! * 12).round();
  }
}

class SocietiesState {
  final bool isLoading;
  final bool isMapLoading;
  final List<SocietyModel> societies;
  final List<SlotPin> slotPins;
  final String? error;
  final String searchQuery;
  final String slotTypeFilter;
  final double? destinationLat;
  final double? destinationLng;
  final List<String> nearbySocietyIds;

  const SocietiesState({
    this.isLoading = false,
    this.isMapLoading = false,
    this.societies = const [],
    this.slotPins = const [],
    this.error,
    this.searchQuery = '',
    this.slotTypeFilter = 'all',
    this.destinationLat,
    this.destinationLng,
    this.nearbySocietyIds = const [],
  });

  SocietiesState copyWith({
    bool? isLoading,
    bool? isMapLoading,
    List<SocietyModel>? societies,
    List<SlotPin>? slotPins,
    String? error,
    String? searchQuery,
    String? slotTypeFilter,
    double? destinationLat,
    double? destinationLng,
    List<String>? nearbySocietyIds,
    bool clearDestination = false,
  }) {
    return SocietiesState(
      isLoading: isLoading ?? this.isLoading,
      isMapLoading: isMapLoading ?? this.isMapLoading,
      societies: societies ?? this.societies,
      slotPins: slotPins ?? this.slotPins,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
        slotTypeFilter: slotTypeFilter ?? this.slotTypeFilter,
      destinationLat: clearDestination
          ? null
          : (destinationLat ?? this.destinationLat),
      destinationLng: clearDestination
          ? null
          : (destinationLng ?? this.destinationLng),
      nearbySocietyIds: nearbySocietyIds ?? this.nearbySocietyIds,
    );
  }

  List<SocietyModel> get filteredSocieties {
    if (searchQuery.isEmpty) return societies;
    return societies
        .where((s) => nearbySocietyIds.contains(s.id))
        .toList(growable: false);
  }

  bool get hasLocationQuery => searchQuery.trim().isNotEmpty;
}

class SocietiesCubit extends Cubit<SocietiesState> {
  final ApiClient _apiClient;
  static const List<double> _fallbackRadiiKm = [0.5, 1.5, 3.0, 6.0];
  static const int _pageSize = 200;

  SocietiesCubit(this._apiClient) : super(const SocietiesState());

  Future<void> loadSocieties() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final societies = await _fetchAllSocieties();
      emit(
        state.copyWith(
          isLoading: false,
          societies: societies,
        ),
      );
      await refreshSlotPins();
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> search(String query) async {
    emit(state.copyWith(searchQuery: query, clearDestination: true));
    await refreshSlotPins();
  }

  Future<void> setSlotTypeFilter(String filter) async {
    emit(state.copyWith(slotTypeFilter: filter));
    await refreshSlotPins();
  }

  Future<void> setDestination(double lat, double lng) async {
    emit(state.copyWith(destinationLat: lat, destinationLng: lng));
    await refreshSlotPins();
  }

  Future<void> clearDestination() async {
    emit(state.copyWith(clearDestination: true));
    await refreshSlotPins();
  }

  Future<void> refreshSlotPins() async {
    final query = state.searchQuery.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          slotPins: const [],
          nearbySocietyIds: const [],
          isMapLoading: false,
          clearDestination: true,
        ),
      );
      return;
    }

    emit(state.copyWith(isMapLoading: true, error: null));

    (double, double)? center;
    if (state.destinationLat != null && state.destinationLng != null) {
      center = (state.destinationLat!, state.destinationLng!);
    } else {
      center = await _geocodeQuery(query);
      if (center != null) {
        emit(
          state.copyWith(
            destinationLat: center.$1,
            destinationLng: center.$2,
          ),
        );
      }
    }

    List<SocietyModel> filtered = const [];
    if (center != null) {
      for (final radiusKm in _fallbackRadiiKm) {
        final matches = _societiesWithinRadius(
          center.$1,
          center.$2,
          radiusKm,
        );
        if (matches.isNotEmpty) {
          filtered = matches;
          break;
        }
      }
    } else {
      filtered = _findMatchingSocieties(query);
    }

    if (filtered.isEmpty) {
      emit(
        state.copyWith(
          slotPins: const [],
          nearbySocietyIds: const [],
          isMapLoading: false,
        ),
      );
      return;
    }

    try {
      final List<SlotPin> pins = [];
      for (final society in filtered) {
        final societyLat = society.latitude;
        final societyLng = society.longitude;
        if (societyLat == null || societyLng == null) continue;

        final slots = await _fetchAllAvailableSlots(society.id);

        for (var s = 0; s < slots.length; s++) {
          final slot = slots[s];
          if (state.slotTypeFilter != 'all' && slot.slotType != state.slotTypeFilter) {
            continue;
          }
          final lat = societyLat;
          final lng = societyLng;

          final distance = _distanceKm(
            state.destinationLat,
            state.destinationLng,
            lat,
            lng,
          );

          pins.add(
            SlotPin(
              society: society,
              slot: slot,
              latitude: lat,
              longitude: lng,
              distanceKm: distance,
            ),
          );
        }
      }

      pins.sort((a, b) {
        if (a.distanceKm == null && b.distanceKm == null) return 0;
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm!.compareTo(b.distanceKm!);
      });

      emit(
        state.copyWith(
          isMapLoading: false,
          slotPins: pins,
          nearbySocietyIds: filtered.map((s) => s.id).toList(growable: false),
          error: null,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(isMapLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isMapLoading: false, error: e.toString()));
    }
  }

  Future<(double, double)?> _geocodeQuery(String query) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.societiesGeocode,
        queryParameters: {'q': query},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final lat = data['latitude'];
      final lng = data['longitude'];
      final latitude = lat is num ? lat.toDouble() : null;
      final longitude = lng is num ? lng.toDouble() : null;
      if (latitude == null || longitude == null) return null;
      return (latitude, longitude);
    } catch (_) {
      return null;
    }
  }

  Future<List<SocietyModel>> _fetchAllSocieties() async {
    final societies = <SocietyModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final response = await _apiClient.get(
        ApiEndpoints.societies,
        queryParameters: {
          'page': page,
          'page_size': _pageSize,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final apiResponse = ApiResponse<SocietyModel>.fromJson(
          data,
          (json) => SocietyModel.fromJson(json),
        );
        societies.addAll(apiResponse.results);
        hasMore = data['next'] != null && apiResponse.results.isNotEmpty;
        page += 1;
        continue;
      }

      if (data is List) {
        societies.addAll(
          data.map((e) => SocietyModel.fromJson(e as Map<String, dynamic>)),
        );
      }
      hasMore = false;
    }

    return societies;
  }

  Future<List<SlotModel>> _fetchAllAvailableSlots(String societyId) async {
    final slots = <SlotModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final response = await _apiClient.get(
        ApiEndpoints.societySlots(societyId),
        queryParameters: {
          'state': 'available',
          'page': page,
          'page_size': _pageSize,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('results')) {
        final pageItems = (data['results'] as List)
            .map((e) => SlotModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        slots.addAll(pageItems);
        hasMore = data['next'] != null && pageItems.isNotEmpty;
        page += 1;
        continue;
      }

      if (data is List) {
        slots.addAll(
          data.map((e) => SlotModel.fromJson(e as Map<String, dynamic>)),
        );
      }
      hasMore = false;
    }

    return slots;
  }

  List<SocietyModel> _findMatchingSocieties(String query) {
    final normalizedQuery = _normalizeLocationText(query);
    if (normalizedQuery.isEmpty) return const [];

    final exactMatches = state.societies.where((society) {
      final candidates = _societyMatchCandidates(society);
      return candidates.any((candidate) => candidate == normalizedQuery);
    }).toList(growable: false);
    if (exactMatches.isNotEmpty) return exactMatches;

    final matches = state.societies.where((society) {
      final candidates = _societyMatchCandidates(society);
      return candidates.any((candidate) =>
          candidate.contains(normalizedQuery) ||
          normalizedQuery.contains(candidate));
    }).toList(growable: false);

    if (matches.isNotEmpty) return matches;

    return state.societies.where((society) {
      final tokens = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();
      if (tokens.isEmpty) return false;

      final candidates = _societyMatchCandidates(society).join(' ');
      return tokens.every(candidates.contains);
    }).toList(growable: false);
  }

  List<String> _societyMatchCandidates(SocietyModel society) {
    return [
      _normalizeLocationText(society.name),
      _normalizeLocationText(society.address),
      _normalizeLocationText(society.city),
      _normalizeLocationText(society.state),
      _normalizeLocationText('${society.city} ${society.state}'),
      _normalizeLocationText('${society.name} ${society.city}'),
      _normalizeLocationText('${society.name} ${society.address}'),
      _normalizeLocationText('${society.name} ${society.address} ${society.city}'),
      _normalizeLocationText('${society.address} ${society.city}'),
      _normalizeLocationText('${society.pincode} ${society.city}'),
    ];
  }

  List<SocietyModel> _societiesWithinRadius(
    double centerLat,
    double centerLng,
    double radiusKm,
  ) {
    return state.societies.where((society) {
      final lat = society.latitude;
      final lng = society.longitude;
      if (lat == null || lng == null) return false;
      final d = _distanceKm(centerLat, centerLng, lat, lng);
      return d != null && d <= radiusKm;
    }).toList(growable: false);
  }

  String _normalizeLocationText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double? _distanceKm(
    double? originLat,
    double? originLng,
    double destLat,
    double destLng,
  ) {
    if (originLat == null || originLng == null) return null;

    const r = 6371.0;
    final dLat = _degToRad(destLat - originLat);
    final dLng = _degToRad(destLng - originLng);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_degToRad(originLat)) *
            math.cos(_degToRad(destLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _degToRad(double deg) => deg * 0.017453292519943295;
}
