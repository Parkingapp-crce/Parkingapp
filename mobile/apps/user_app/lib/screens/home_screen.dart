import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:core/core.dart';

import '../cubits/societies_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SocietiesCubit(GetIt.instance<ApiClient>())..loadSocieties(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  Timer? _refreshTimer;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;
        context.read<SocietiesCubit>().refreshSlotPins();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocietiesCubit, SocietiesState>(
      builder: (context, state) {
        final suggestions = _buildSuggestions(state.societies, _searchText);
        final showSuggestions =
            _searchText.trim().isNotEmpty && suggestions.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ParkEase'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final name = authState is Authenticated
                        ? authState.user.fullName
                        : 'there';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $name',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heading to?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _VehicleTypeFilterBar(
                          selectedType: state.slotTypeFilter,
                          onChanged: (type) {
                            context.read<SocietiesCubit>().setSlotTypeFilter(type);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            setState(() {
                              _searchText = value;
                            });

                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(
                              const Duration(milliseconds: 350),
                              () {
                                if (!mounted) return;
                                context.read<SocietiesCubit>().search(value);
                              },
                            );
                          },
                          onSubmitted: (_) {
                            _searchDebounce?.cancel();
                            _applySuggestion(
                              context,
                              _searchText,
                            );
                          },
                          decoration: InputDecoration(
                            hintText: 'Search location, tower, or society',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                          ),
                        ),
                        if (showSuggestions)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 14,
                                  color: Color(0x14000000),
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: suggestions.length,
                              separatorBuilder: (_, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = suggestions[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined,
                                      color: AppColors.primary),
                                  title: Text(suggestion),
                                  onTap: () => _applySuggestion(
                                    context,
                                    suggestion,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const _NearbySlotsMap(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const LoadingWidget(message: 'Loading societies...');
                    }

                    if (state.error != null) {
                      return AppErrorWidget(
                        message: state.error!,
                        onRetry: () =>
                            context.read<SocietiesCubit>().loadSocieties(),
                      );
                    }

                    if (!state.hasLocationQuery) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Find parking near your destination',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enter a location above to instantly see nearby available parking spots within a 500 meter radius.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified,
                                        color: AppColors.success,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Only currently available spots are shown.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final pins = state.slotPins;
                    if (pins.isEmpty) {
                      return const EmptyStateWidget(
                        icon: Icons.place_outlined,
                        title: 'No parking spots in 500m radius',
                        subtitle: 'Try a more precise nearby landmark or address',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<SocietiesCubit>().refreshSlotPins(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ResultSummaryCard(
                            location: state.searchQuery,
                            spotsCount: pins.length,
                          ),
                          const SizedBox(height: 12),
                          ...pins.map((pin) => _NearbySpotCard(pin: pin)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _buildSuggestions(List<SocietyModel> societies, String query) {
    final normalized = query.trim().toLowerCase();

    final candidates = <String>{};
    for (final society in societies) {
      candidates.addAll(_societyLocationCandidates(society));
    }

    if (normalized.isEmpty) {
      return candidates.take(12).toList(growable: false);
    }

    final ranked = candidates.where((candidate) {
      return candidate.toLowerCase().contains(normalized);
    }).toList(growable: false);

    ranked.sort((a, b) {
      final aStarts = a.toLowerCase().startsWith(normalized);
      final bStarts = b.toLowerCase().startsWith(normalized);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return a.length.compareTo(b.length);
    });

    return ranked.take(12).toList(growable: false);
  }

  List<String> _societyLocationCandidates(SocietyModel society) {
    return [
      society.name,
      society.address,
      society.city,
      society.state,
      '${society.city}, ${society.state}',
      '${society.name}, ${society.city}',
      '${society.name}, ${society.address}',
      '${society.name}, ${society.address}, ${society.city}',
      '${society.address}, ${society.city}',
      '${society.pincode}, ${society.city}',
    ];
  }

  void _applySuggestion(BuildContext context, String value) {
    _searchDebounce?.cancel();
    final trimmedValue = value.trim();
    setState(() {
      _searchText = trimmedValue;
      _searchController.text = trimmedValue;
      _searchController.selection =
          TextSelection.collapsed(offset: trimmedValue.length);
    });
    _searchFocusNode.unfocus();
    context.read<SocietiesCubit>().search(trimmedValue);
  }
}

class _ResultSummaryCard extends StatelessWidget {
  final String location;
  final int spotsCount;

  const _ResultSummaryCard({
    required this.location,
    required this.spotsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_parking, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$spotsCount spots available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Near "$location"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbySpotCard extends StatelessWidget {
  final SlotPin pin;

  const _NearbySpotCard({required this.pin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pin.society.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '₹${pin.slot.hourlyRate}/hr',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${pin.society.address}, ${pin.society.city}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Slot ${pin.slot.slotNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  pin.distanceKm == null
                      ? 'within 500m'
                      : '${pin.distanceKm!.toStringAsFixed(2)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      '/booking/create?societyId=${pin.society.id}&slotId=${pin.slot.id}',
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Book'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbySlotsMap extends StatefulWidget {
  const _NearbySlotsMap();

  @override
  State<_NearbySlotsMap> createState() => _NearbySlotsMapState();
}

class _NearbySlotsMapState extends State<_NearbySlotsMap> {
  late MapController _mapController;
  (double, double)? _lastAnimatedCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _animateToCenter(double lat, double lng) {
    if (_lastAnimatedCenter == null ||
        _lastAnimatedCenter!.$1 != lat ||
        _lastAnimatedCenter!.$2 != lng) {
      _lastAnimatedCenter = (lat, lng);
      _mapController.move(
        latlng.LatLng(lat, lng),
        14,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocietiesCubit, SocietiesState>(
      builder: (context, state) {
        if (!state.hasLocationQuery) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter a location to find nearby parking spots on map.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.destinationLat != null && state.destinationLng != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateToCenter(state.destinationLat!, state.destinationLng!);
          });
        }

        final mapMarkers = state.slotPins
            .map(
              (pin) => Marker(
                width: 44,
                height: 44,
                point: latlng.LatLng(pin.latitude, pin.longitude),
                child: GestureDetector(
                  onTap: () => _showPinDetail(context, pin),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: true);

        if (state.destinationLat != null && state.destinationLng != null) {
          mapMarkers.add(
            Marker(
              width: 42,
              height: 42,
              point: latlng.LatLng(state.destinationLat!, state.destinationLng!),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 20),
              ),
            ),
          );
        }

        final center =
            (state.destinationLat != null && state.destinationLng != null)
                ? latlng.LatLng(state.destinationLat!, state.destinationLng!)
                : (state.slotPins.isNotEmpty
                    ? latlng.LatLng(
                        state.slotPins.first.latitude,
                        state.slotPins.first.longitude,
                      )
                    : latlng.LatLng(19.0760, 72.8777));

        final searchCircle =
            state.destinationLat != null && state.destinationLng != null
                ? CircleMarker(
                    point: latlng.LatLng(
                      state.destinationLat!,
                      state.destinationLng!,
                    ),
                    radius: 500,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderColor: AppColors.primary,
                    borderStrokeWidth: 2,
                  )
                : null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Nearby Parking Spots',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (state.destinationLat != null && state.destinationLng != null)
                    TextButton.icon(
                      onPressed: () {
                        context.read<SocietiesCubit>().clearDestination();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Destination'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: 14,
                          minZoom: 3,
                          maxZoom: 19,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=${EnvConfig.dev.mapTilerApiKey}',
                            userAgentPackageName: 'com.parkwise.user_app',
                          ),
                          if (searchCircle != null)
                            CircleLayer(circles: [searchCircle]),
                          MarkerLayer(markers: mapMarkers),
                        ],
                      ),
                      if (state.isMapLoading)
                        Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Only available parking spots within 500 meters are shown after you select a location.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPinDetail(BuildContext context, SlotPin pin) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final walkText = pin.walkingMinutes == null
            ? 'Set destination on map for walking estimate'
            : '${pin.walkingMinutes} min walk • ${pin.distanceKm!.toStringAsFixed(2)} km';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot ${pin.slot.slotNumber}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                pin.society.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${pin.society.address}, ${pin.society.city}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _detailChip(context, Icons.currency_rupee, '₹${pin.slot.hourlyRate}/hr'),
                  const SizedBox(width: 8),
                  _detailChip(context, Icons.local_parking, pin.slot.slotType.toUpperCase()),
                ],
              ),
              const SizedBox(height: 8),
              if (pin.slot.availableFrom != null && pin.slot.availableTo != null) ...[
                _detailChip(
                  context,
                  Icons.access_time,
                  '${pin.slot.availableFrom} - ${pin.slot.availableTo}',
                ),
                const SizedBox(height: 8),
              ],
              _detailChip(context, Icons.directions_walk, walkText),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Select This Slot',
                  icon: Icons.check_circle_outline,
                  onPressed: () {
                    context.pop();
                    context.push(
                      '/booking/create?societyId=${pin.society.id}&slotId=${pin.slot.id}',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}


class _VehicleTypeFilterBar extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _VehicleTypeFilterBar({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Vehicle: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'All',
            selected: selectedType == 'all',
            onTap: () => onChanged('all'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Car',
            selected: selectedType == 'car',
            onTap: () => onChanged('car'),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Bike',
            selected: selectedType == 'bike',
            onTap: () => onChanged('bike'),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

