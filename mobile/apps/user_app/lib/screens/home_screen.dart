import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../cubits/societies_cubit.dart';
import 'destination_picker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SocietiesCubit(GetIt.instance<ApiClient>()),
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
  late DateTime _bookingDate;
  late TimeOfDay _startTime;
  bool _useDuration = true;
  int _durationMinutes = 60;
  TimeOfDay? _endTime;
  String _vehicleType = 'car';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _bookingDate = DateTime(now.year, now.month, now.day);
    _startTime = _nextHour(now);
    _endTime = _addMinutes(_startTime, _durationMinutes);
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Parking')),
      body: BlocBuilder<SocietiesCubit, SocietiesState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<SocietiesCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Search nearby societies',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a destination from suggestions or map, then search by booking window and vehicle type.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearchCard(context, state),
                const SizedBox(height: 16),
                _buildResultsSection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context, SocietiesState state) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Destination',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: state.destinationSuggestions
                      .map(
                        (suggestion) => ListTile(
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
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
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickOnMap(context, state),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Pick on Map'),
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
            const SizedBox(height: 20),
            Text(
              'Booking Filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_today,
                color: AppColors.primary,
              ),
              title: const Text('Booking Date'),
              subtitle: Text(dateFormat.format(_bookingDate)),
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
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: AppColors.primary),
              title: const Text('Start Time'),
              subtitle: Text(_startTime.format(context)),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Use Duration'),
                  selected: _useDuration,
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
                  onSelected: (_) {
                    setState(() {
                      _useDuration = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.access_time_filled,
                  color: AppColors.primary,
                ),
                title: const Text('End Time'),
                subtitle: Text(_endTime?.format(context) ?? 'Select end time'),
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
            const SizedBox(height: 16),
            Text(
              'Vehicle Type',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Car'),
                  selected: _vehicleType == 'car',
                  onSelected: (_) => setState(() => _vehicleType = 'car'),
                ),
                ChoiceChip(
                  label: const Text('Bike'),
                  selected: _vehicleType == 'bike',
                  onSelected: (_) => setState(() => _vehicleType = 'bike'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Find Available Parking',
              isLoading: state.isLoading,
              icon: Icons.search,
              onPressed: () => _submitSearch(context),
            ),
          ],
        ),
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
          Text(
            'Results near ${state.resolvedDestinationLabel}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Sorted by distance${state.searchRadiusKm != null ? ' within ${state.searchRadiusKm!.toStringAsFixed(0)} km' : ''}.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        ...state.results.map(
          (society) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SocietyCard(society: society, request: state.lastRequest!),
          ),
        ),
      ],
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
    _autocompleteDebounce = Timer(
      const Duration(milliseconds: 350),
      () => cubit.loadDestinationSuggestions(trimmed),
    );
  }

  void _selectSuggestion(
    BuildContext context,
    LocationSuggestionModel suggestion,
  ) {
    _destinationController.text = suggestion.label;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
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

class _SocietyCard extends StatelessWidget {
  final SocietySearchResultModel society;
  final SocietySearchRequest request;

  const _SocietyCard({required this.society, required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: AppColors.primary,
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
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${society.address}, ${society.city}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${society.distanceKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    color: AppColors.primary,
                  ),
                  _InfoPill(
                    icon: society.vehicleType == 'bike'
                        ? Icons.two_wheeler
                        : Icons.directions_car,
                    label: society.vehicleType.toUpperCase(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
