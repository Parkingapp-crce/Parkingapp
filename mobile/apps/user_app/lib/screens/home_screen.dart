import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubits/bookings_cubit.dart';
import '../cubits/penalties_cubit.dart';
import '../cubits/societies_cubit.dart';
import 'destination_picker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = GetIt.instance<ApiClient>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SocietiesCubit(apiClient)),
        BlocProvider(
          create: (_) => BookingsCubit(apiClient)
            ..loadBookings()
            ..startPolling(),
        ),
        BlocProvider(
          create: (_) => PenaltiesCubit(apiClient)..load(status: 'unpaid'),
        ),
      ],
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
  final _destinationController = TextEditingController();

  Timer? _autocompleteDebounce;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  late DateTime _bookingDate;
  late TimeOfDay _startTime;
  bool _useDuration = true;
  int _durationMinutes = 60;
  TimeOfDay? _endTime;
  String _vehicleType = 'car';
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bookingDate = DateTime(now.year, now.month, now.day);
    _startTime = _nextHour(now);
    _endTime = _addMinutes(_startTime, _durationMinutes);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _clockTimer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'PARKWISE',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          BlocBuilder<BookingsCubit, BookingsState>(
            builder: (context, bookingState) {
              final blockingBooking = _blockingBooking(bookingState.bookings);
              if (blockingBooking != null) {
                return Container(
                  margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_parking_rounded,
                          color: Theme.of(context).colorScheme.tertiary, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PARKING ACTIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      body: BlocBuilder<PenaltiesCubit, PenaltiesState>(
        builder: (context, penaltyState) {
          return BlocBuilder<BookingsCubit, BookingsState>(
            builder: (context, bookingState) {
              final blockingBooking = _blockingBooking(bookingState.bookings);

              return BlocBuilder<SocietiesCubit, SocietiesState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        context.read<PenaltiesCubit>().load(status: 'unpaid'),
                        context.read<SocietiesCubit>().refresh(),
                        context.read<BookingsCubit>().loadBookings(),
                      ]);
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (blockingBooking != null) ...[
                          _ParkingInProgressCard(
                            booking: blockingBooking,
                            now: _now,
                            onNavigate: () => _openNavigation(blockingBooking),
                            onOpenBooking: () =>
                                context.push('/bookings/${blockingBooking.id}'),
                          ),
                        ] else if (penaltyState.penalties.isNotEmpty) ...[
                          Card(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 48, color: Theme.of(context).colorScheme.error),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Action Required',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have an unpaid overstay penalty on your profile. You cannot book new slots until all dues are cleared.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  PrimaryButton(
                                    label: 'Go to Booking to Pay Penalty',
                                    onPressed: () {
                                      final firstPenalty = penaltyState.penalties.first;
                                      context.push('/bookings/${firstPenalty.booking}');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildWelcomeGreeting(context),
                          _buildSearchCard(context, state),
                          const SizedBox(height: 16),
                          _buildResultsSection(context, state),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  BookingModel? _blockingBooking(List<BookingModel> bookings) {
    final now = DateTime.now();
    for (final booking in bookings) {
      if (_bookingBlocksUser(booking, now)) {
        return booking;
      }
    }
    return null;
  }

  bool _bookingBlocksUser(BookingModel booking, DateTime now) {
    if (booking.isPendingPayment) {
      return true;
    }

    if (booking.isConfirmed) {
      return false;
    }

    if (booking.isActive) {
      final hasExitTime = booking.actualExit != null && booking.actualExit!.isNotEmpty;
      return !hasExitTime;
    }

    return false;
  }

  Future<void> _openNavigation(BookingModel booking) async {
    final lat = booking.societyLatitude;
    final lng = booking.societyLongitude;
    if (lat == null || lng == null) {
      return;
    }

    final mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
    );
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }

  Widget _buildSearchCard(BuildContext context, SocietiesState state) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return PremiumCard(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
      ),
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destination',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            textInputAction: TextInputAction.search,
            onChanged: _onDestinationChanged,
            decoration: InputDecoration(
              hintText: 'Where do you need parking?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.selectedDestination != null
                  ? IconButton(
                      tooltip: 'Clear destination',
                      onPressed: () {
                        _destinationController.clear();
                        context
                            .read<SocietiesCubit>()
                            .clearDestinationSelection();
                      },
                      icon: const Icon(Icons.close),
                    )
                  : null,
            ),
          ),
          if (state.isLoadingSuggestions) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (state.destinationSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                children: state.destinationSuggestions
                    .map(
                      (suggestion) => ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(suggestion.title),
                        subtitle: suggestion.subtitle.isNotEmpty
                            ? Text(
                                suggestion.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () => _selectSuggestion(context, suggestion),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: state.isResolvingLocation
                    ? null
                    : () => _useCurrentLocation(context),
                icon: state.isResolvingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: const Text('Use Current Location'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickOnMap(context, state),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Pick on Map'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          if (state.selectedDestination != null) ...[
            const SizedBox(height: 12),
            _LocationSummaryCard(
              title: 'Selected Destination',
              location: state.selectedDestination!,
              icon: Icons.place_outlined,
            ),
          ],
          if (state.currentLocation != null &&
              state.currentLocation?.label !=
                  state.selectedDestination?.label) ...[
            const SizedBox(height: 12),
            _LocationSummaryCard(
              title: 'Current Location Helper',
              location: state.currentLocation!,
              icon: Icons.my_location_outlined,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Booking Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),

          // Booking Date selector tile
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'BOOKING DATE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              subtitle: Text(
                dateFormat.format(_bookingDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _bookingDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() {
                    _bookingDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                    );
                  });
                }
              },
            ),
          ),

          // Start Time selector tile
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'START TIME',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
              ),
              subtitle: Text(
                _startTime.format(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (picked != null) {
                  setState(() {
                    _startTime = picked;
                    if (_useDuration) {
                      _endTime = _addMinutes(picked, _durationMinutes);
                    }
                  });
                }
              },
            ),
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Use Duration'),
                selected: _useDuration,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: _useDuration 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: _useDuration ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  setState(() {
                    _useDuration = true;
                    _endTime = _addMinutes(_startTime, _durationMinutes);
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Use End Time'),
                selected: !_useDuration,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: !_useDuration 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: !_useDuration ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  setState(() {
                    _useDuration = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_useDuration)
            DropdownButtonFormField<int>(
              initialValue: _durationMinutes,
              decoration: const InputDecoration(
                labelText: 'Duration',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 minutes')),
                DropdownMenuItem(value: 60, child: Text('1 hour')),
                DropdownMenuItem(value: 120, child: Text('2 hours')),
                DropdownMenuItem(value: 180, child: Text('3 hours')),
                DropdownMenuItem(value: 240, child: Text('4 hours')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _durationMinutes = value;
                  _endTime = _addMinutes(_startTime, _durationMinutes);
                });
              },
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'END TIME',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
                subtitle: Text(
                  _endTime?.format(context) ?? 'Select end time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? _addMinutes(_startTime, 60),
                  );
                  if (picked != null) {
                    setState(() {
                      _endTime = picked;
                    });
                  }
                },
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Vehicle Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Car'),
                selected: _vehicleType == 'car',
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: _vehicleType == 'car'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: _vehicleType == 'car' ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _vehicleType = 'car'),
              ),
              ChoiceChip(
                label: const Text('Bike'),
                selected: _vehicleType == 'bike',
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: _vehicleType == 'bike'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: _vehicleType == 'bike' ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setState(() => _vehicleType = 'bike'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HomeScreenGradientButton(
            label: 'Find Available Parking',
            isLoading: state.isLoading,
            icon: Icons.search_rounded,
            onPressed: () => _submitSearch(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context, SocietiesState state) {
    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => context.read<SocietiesCubit>().refresh(),
      );
    }

    if (!state.hasSearched) {
      return const EmptyStateWidget(
        icon: Icons.travel_explore_outlined,
        title: 'Pick a destination to search',
        subtitle:
            'Select a real place suggestion or map point first, then search by booking window and vehicle type.',
      );
    }

    if (state.isLoading) {
      return const LoadingWidget(message: 'Searching societies...');
    }

    if (state.results.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'No societies available',
        subtitle:
            'No nearby societies currently have a matching slot for that time window and vehicle type.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.resolvedDestinationLabel != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results near ${state.resolvedDestinationLabel}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sorted by distance${state.searchRadiusKm != null ? ' within ${state.searchRadiusKm!.toStringAsFixed(0)} km' : ''}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: Icon(_showMap ? Icons.list : Icons.map),
                tooltip: _showMap ? 'List View' : 'Map View',
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_showMap)
          _buildResultsMap(context, state)
        else
          ...state.results.map(
            (society) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SocietyCard(
                society: society,
                request: state.lastRequest!,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsMap(BuildContext context, SocietiesState state) {
    final validResults = state.results
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();
    final destination = state.selectedDestination;

    if (validResults.isEmpty && destination == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No location data available.')),
      );
    }

    final markers = <Marker>[];
    final polylines = <Polyline>[];

    // Add Destination Marker
    if (destination != null) {
      markers.add(
        Marker(
          point: LatLng(destination.latitude, destination.longitude),
          width: 44,
          height: 44,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
          ),
        ),
      );
    }

    // Add Society Markers and Polylines
    for (final s in validResults) {
      final societyPoint = LatLng(s.latitude!, s.longitude!);

      // Add Polyline from destination to society
      if (destination != null) {
        polylines.add(
          Polyline(
            points: [
              LatLng(destination.latitude, destination.longitude),
              societyPoint,
            ],
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            strokeWidth: 3,
            borderColor: Colors.white,
            borderStrokeWidth: 1,
          ),
        );

        // Add Distance Label Marker at midpoint
        final midLat = (destination.latitude + s.latitude!) / 2;
        final midLng = (destination.longitude + s.longitude!) / 2;
        markers.add(
          Marker(
            point: LatLng(midLat, midLng),
            width: 70,
            height: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${s.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // Add Society Marker
      markers.add(
        Marker(
          point: societyPoint,
          width: 80,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              // Show bottom sheet with the society details when tapped
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _SocietyCard(society: s, request: state.lastRequest!),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                  child: const Text(
                    'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  transform: Matrix4.translationValues(0, -2, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹${s.startingHourlyRate}/hr',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initialCenter = destination != null
        ? LatLng(destination.latitude, destination.longitude)
        : (validResults.isNotEmpty
              ? LatLng(
                  validResults.first.latitude!,
                  validResults.first.longitude!,
                )
              : const LatLng(
                  19.0760,
                  72.8777,
                )); // Mumbai default if nothing else

    return SizedBox(
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              key: const ValueKey('homeTileLayer'),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.parkease.user_app',
            ),
            PolylineLayer(
              key: const ValueKey('homePolylineLayer'),
              polylines: polylines,
            ),
            MarkerLayer(
              key: const ValueKey('homeMarkerLayer'),
              markers: markers,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSearch(BuildContext context) async {
    final cubit = context.read<SocietiesCubit>();
    final selectedDestination = cubit.state.selectedDestination;
    if (selectedDestination == null) {
      _showMessage(
        context,
        'Choose a destination suggestion or pick a point on the map first.',
      );
      return;
    }

    final endTime = _resolvedEndTime();
    if (endTime == null) {
      _showMessage(context, 'Select a valid end time or duration.');
      return;
    }

    final startDateTime = _combineDateAndTime(_bookingDate, _startTime);
    final endDateTime = _combineDateAndTime(_bookingDate, endTime);
    if (!endDateTime.isAfter(startDateTime)) {
      _showMessage(context, 'End time must be after start time.');
      return;
    }

    final request = SocietySearchRequest(
      destination: selectedDestination,
      currentLocation: cubit.state.currentLocation,
      bookingDate: DateFormat('yyyy-MM-dd').format(_bookingDate),
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(endTime),
      vehicleType: _vehicleType,
    );

    await cubit.searchAvailability(request);
  }

  Future<void> _useCurrentLocation(BuildContext context) async {
    final cubit = context.read<SocietiesCubit>();
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!context.mounted) {
      return;
    }
    if (!servicesEnabled) {
      _showMessage(
        context,
        'Turn on location services to use current location.',
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (!context.mounted) {
      return;
    }
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!context.mounted) {
        return;
      }
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage(context, 'Location permission is required for this helper.');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (!context.mounted) {
      return;
    }
    final location = await cubit.reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
      setAsDestination: true,
      setAsCurrentLocation: true,
    );
    if (!context.mounted || location == null) {
      return;
    }

    _destinationController.text = location.label;
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickOnMap(BuildContext context, SocietiesState state) async {
    final cubit = context.read<SocietiesCubit>();
    final pickedPoint = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => DestinationPickerScreen(
          initialLocation: state.selectedDestination ?? state.currentLocation,
        ),
      ),
    );

    if (!context.mounted || pickedPoint == null) {
      return;
    }

    final location = await cubit.reverseGeocode(
      latitude: pickedPoint.latitude,
      longitude: pickedPoint.longitude,
      setAsDestination: true,
    );
    if (!context.mounted || location == null) {
      return;
    }

    _destinationController.text = location.label;
    FocusScope.of(context).unfocus();
  }

  void _onDestinationChanged(String value) {
    final cubit = context.read<SocietiesCubit>();
    final trimmed = value.trim();
    if (cubit.state.selectedDestination?.label != trimmed &&
        cubit.state.selectedDestination != null) {
      cubit.clearDestinationSelection();
    }

    _autocompleteDebounce?.cancel();
    // Increased debounce to 1500ms to stay within Nominatim's 1 req/sec limit
    _autocompleteDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (trimmed.isNotEmpty) {
        cubit.loadDestinationSuggestions(trimmed);
      }
    });
  }

  void _selectSuggestion(BuildContext context, dynamic suggestion) {
    context.read<SocietiesCubit>().selectDestination(suggestion);
    FocusScope.of(context).unfocus();
  }

  TimeOfDay? _resolvedEndTime() {
    if (_useDuration) {
      return _addMinutes(_startTime, _durationMinutes);
    }
    return _endTime;
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _nextHour(DateTime now) {
    final next = now.add(const Duration(hours: 1));
    return TimeOfDay(hour: next.hour, minute: 0);
  }

  TimeOfDay _addMinutes(TimeOfDay base, int minutes) {
    final totalMinutes = base.hour * 60 + base.minute + minutes;
    final normalized = totalMinutes % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildWelcomeGreeting(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state is Authenticated ? state.user.fullName : 'Guest';
        final hour = DateTime.now().hour;
        String greeting = 'Good morning';
        if (hour >= 12 && hour < 17) {
          greeting = 'Good afternoon';
        } else if (hour >= 17 || hour < 4) {
          greeting = 'Good evening';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$name 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  final String title;
  final LocationSuggestionModel location;
  final IconData icon;

  const _LocationSummaryCard({
    required this.title,
    required this.location,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  location.label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Lat ${location.latitude.toStringAsFixed(6)}  |  Lng ${location.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _SocietyCard extends StatelessWidget {
  final SocietySearchResultModel society;
  final SocietySearchRequest request;

  const _SocietyCard({required this.society, required this.request});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
      ),
      borderRadius: 16,
      onTap: () {
        final uri = Uri(
          path: '/societies/${society.id}',
          queryParameters: {
            'bookingDate': request.bookingDate,
            'startTime': request.startTime,
            'endTime': request.endTime,
            'vehicleType': request.vehicleType,
          },
        );
        context.push(uri.toString());
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        society.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${society.address}, ${society.city}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontFamily: 'Inter',
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${society.distanceKm.toStringAsFixed(1)} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.2,
                            fontFamily: 'Inter',
                          ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  icon: Icons.local_parking_outlined,
                  label: '${society.availableSlots} matching slots',
                  color: AppColors.success,
                ),
                _InfoPill(
                  icon: Icons.currency_rupee,
                  label: 'From ${society.startingHourlyRate}/hr',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _InfoPill(
                  icon: society.vehicleType == 'bike'
                      ? Icons.two_wheeler
                      : Icons.directions_car,
                  label: society.vehicleType.toUpperCase(),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingInProgressCard extends StatelessWidget {
  final BookingModel booking;
  final DateTime now;
  final VoidCallback onNavigate;
  final VoidCallback onOpenBooking;

  const _ParkingInProgressCard({
    required this.booking,
    required this.now,
    required this.onNavigate,
    required this.onOpenBooking,
  });

  /// Format a duration as HH:MM:SS
  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Compute the estimated penalty accrued right now.
  /// Rate = 20% of booking amount per *started* hour of overstay (ceil).
  double _estimatedPenalty(Duration overstay) {
    if (!overstay.isNegative && overstay.inSeconds <= 0) return 0;
    final bookingAmount = double.tryParse(booking.amount) ?? 0;
    final penaltyPerHour = bookingAmount * 0.20;
    // ceil every started hour
    final hoursStarted = (overstay.inSeconds / 3600).ceil();
    return penaltyPerHour * hoursStarted;
  }

  @override
  Widget build(BuildContext context) {
    // ── Parse dates ────────────────────────────────────────────────────────
    DateTime? endTime;
    DateTime? actualEntry;
    DateTime? actualExit;
    try {
      endTime = DateTime.parse(booking.endTime).toLocal();
      if (booking.actualEntry?.isNotEmpty == true) {
        actualEntry = DateTime.parse(booking.actualEntry!).toLocal();
      }
      if (booking.actualExit?.isNotEmpty == true) {
        actualExit = DateTime.parse(booking.actualExit!).toLocal();
      }
    } catch (_) {}

    final hasEntryScan = actualEntry != null;
    final isActive = booking.isActive || hasEntryScan;
    final isConfirmed = booking.isConfirmed && !hasEntryScan;

    // ── Overtime detection ─────────────────────────────────────────────────
    final isOvertime = isActive &&
        actualExit == null &&
        endTime != null &&
        now.isAfter(endTime);

    final remaining = endTime == null ? null : endTime.difference(now);
    final overstay = endTime == null ? Duration.zero : now.difference(endTime);
    final estimatedPenalty = isOvertime ? _estimatedPenalty(overstay) : 0.0;

    // ── Status label ───────────────────────────────────────────────────────
    final statusLabel = isOvertime
        ? 'OVERTIME — EXIT IMMEDIATELY'
        : isActive
            ? 'Parking in progress'
            : isConfirmed
                ? 'Reserved, waiting for entry'
                : 'Payment pending';

    // ── Card gradient — danger red in overtime, default navy otherwise ─────
    final cardGradient = isOvertime
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0A0A), Color(0xFF3B1111), Color(0xFF1A0505)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1220)],
          );

    final accentColor =
        isOvertime ? Color(0xFFFF4444) : Theme.of(context).colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: isOvertime
            ? Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.45), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (isOvertime ? const Color(0xFFFF2222) : Colors.black)
                .withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Overtime warning banner ──────────────────────────────────────
          if (isOvertime)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFF2222),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'PENALTY ACCRUING — SCAN EXIT QR NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isOvertime
                            ? Icons.warning_amber_rounded
                            : Icons.local_parking_rounded,
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: isOvertime
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.societyName ?? 'Parking destination',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        isOvertime
                            ? 'OVERTIME'
                            : booking.status
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Timer row ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: isOvertime
                          // Overtime counter counting UP in red
                          ? _OvertimeCounter(
                              overstayText: _formatDuration(overstay),
                            )
                          : _MetricTile(
                              label: isActive ? 'Time remaining' : 'Entry status',
                              value: isActive
                                  ? (remaining != null
                                      ? _formatDuration(
                                          remaining.isNegative
                                              ? Duration.zero
                                              : remaining)
                                      : '--:--:--')
                                  : 'Waiting for scan',
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: isOvertime
                          // Estimated penalty display
                          ? _PenaltyTile(
                              amount: estimatedPenalty,
                              overstayMinutes: overstay.inMinutes,
                            )
                          : _MetricTile(
                              label: 'Slot',
                              value: booking.slotNumber ?? '--',
                            ),
                    ),
                  ],
                ),

                // ── Slot pill when in overtime (since we use both tiles for timer/penalty) ──
                if (isOvertime && booking.slotNumber != null) ...[
                  const SizedBox(height: 10),
                  _MiniPill(
                    icon: Icons.local_parking_outlined,
                    text: 'Slot ${booking.slotNumber}',
                  ),
                ],

                // ── Entry / exit pills ────────────────────────────────────────
                if (actualEntry != null || actualExit != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (actualEntry != null)
                        _MiniPill(
                          icon: Icons.login_rounded,
                          text:
                              'Entered ${DateFormat('hh:mm a').format(actualEntry)}',
                        ),
                      if (actualExit != null)
                        _MiniPill(
                          icon: Icons.logout_rounded,
                          text:
                              'Exited ${DateFormat('hh:mm a').format(actualExit)}',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // ── Contextual body copy ──────────────────────────────────────
                Text(
                  isOvertime
                      ? 'Your booked time has ended. A penalty of ₹${estimatedPenalty.toStringAsFixed(2)} has accrued (20% of booking amount per started hour). Ask the guard to scan your exit QR now to stop further charges.'
                      : isActive
                          ? 'Your parking session is live. Use the route button if you need directions back to the spot.'
                          : 'Your slot is reserved. Keep this card handy until the entry scan starts your countdown.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                        fontFamily: 'Inter',
                      ),
                ),
                const SizedBox(height: 18),

                // ── Action buttons ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: booking.societyLatitude != null &&
                                booking.societyLongitude != null
                            ? onNavigate
                            : null,
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Navigate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: isOvertime ? 'Show QR' : 'Open Booking',
                        onPressed: onOpenBooking,
                        icon: isOvertime
                            ? Icons.qr_code_rounded
                            : Icons.receipt_long_rounded,
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
}

/// Red pulsing overtime counter widget (counts UP).
class _OvertimeCounter extends StatefulWidget {
  final String overstayText;

  const _OvertimeCounter({required this.overstayText});

  @override
  State<_OvertimeCounter> createState() => _OvertimeCounterState();
}

class _OvertimeCounterState extends State<_OvertimeCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2222).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _opacity,
                builder: (_, child) => Opacity(
                  opacity: _opacity.value,
                  child: child,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF4444), size: 13),
              ),
              const SizedBox(width: 5),
              const Text(
                'OVERTIME',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Text(
              widget.overstayText,
              style: TextStyle(
                color: Color.lerp(
                    const Color(0xFFFF6B6B), const Color(0xFFFFAAAA), _opacity.value),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estimated penalty accrual tile.
class _PenaltyTile extends StatelessWidget {
  final double amount;
  final int overstayMinutes;

  const _PenaltyTile({required this.amount, required this.overstayMinutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2222).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EST. PENALTY',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFFFAAAA),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$overstayMinutes min over',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeScreenGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _HomeScreenGradientButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasCallback = onPressed != null && !isLoading;
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: hasCallback ? AppColors.gradPrimary : null,
        color: hasCallback ? null : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasCallback ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasCallback ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

