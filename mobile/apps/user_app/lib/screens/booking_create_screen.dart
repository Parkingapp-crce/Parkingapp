import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:core/core.dart';

import '../cubits/bookings_cubit.dart';

class BookingCreateScreen extends StatelessWidget {
  final String societyId;
  final String slotId;

  const BookingCreateScreen({
    super.key,
    required this.societyId,
    required this.slotId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookingCreateCubit(GetIt.instance<ApiClient>())
        ..initialize(societyId: societyId, slotId: slotId),
      child: const _BookingCreateContent(),
    );
  }
}

class _BookingCreateContent extends StatelessWidget {
  const _BookingCreateContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Slot'),
      ),
      body: BlocConsumer<BookingCreateCubit, BookingCreateState>(
        listener: (context, state) {
          if (state.createdBooking != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/bookings/${state.createdBooking!.id}');
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingWidget(message: 'Loading slot details...');
          }

          if (state.slot == null) {
            return const AppErrorWidget(message: 'Failed to load slot details');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SlotInfoCard(state: state),
                const SizedBox(height: 16),
                _DateTimeSection(state: state),
                const SizedBox(height: 16),
                _VehicleSelector(state: state),
                const SizedBox(height: 16),
                _AmountDisplay(state: state),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Confirm Booking',
                  isLoading: state.isCreating,
                  onPressed: () =>
                      context.read<BookingCreateCubit>().createBooking(),
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SlotInfoCard extends StatelessWidget {
  final BookingCreateState state;

  const _SlotInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final slot = state.slot!;
    final society = state.society;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.grid_view,
              label: 'Slot Number',
              value: slot.slotNumber,
            ),
            if (society != null)
              _InfoRow(
                icon: Icons.apartment,
                label: 'Society',
                value: society.name,
              ),
            _InfoRow(
              icon: slot.slotType == 'bike'
                  ? Icons.two_wheeler
                  : Icons.directions_car,
              label: 'Type',
              value: slot.slotType.toUpperCase(),
            ),
            if (slot.floor.isNotEmpty)
              _InfoRow(
                icon: Icons.layers,
                label: 'Floor',
                value: slot.floor,
              ),
            _InfoRow(
              icon: Icons.currency_rupee,
              label: 'Hourly Rate',
              value: '${slot.hourlyRate}/hr',
            ),
            if (slot.availableFrom != null && slot.availableTo != null)
              _InfoRow(
                icon: Icons.access_time,
                label: 'Availability',
                value: '${slot.availableFrom} - ${slot.availableTo}',
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeSection extends StatelessWidget {
  final BookingCreateState state;

  const _DateTimeSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCreateCubit>();
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('Date'),
              subtitle: Text(
                state.startDate != null
                    ? dateFormat.format(state.startDate!)
                    : 'Select date',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.startDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  cubit.setStartDate(date);
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('Start Time'),
              subtitle: Text(
                state.startTime != null
                    ? timeFormat.format(state.startTime!)
                    : 'Select start time',
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: state.startTime != null
                      ? TimeOfDay.fromDateTime(state.startTime!)
                      : TimeOfDay.now(),
                );
                if (time != null) {
                  final now = DateTime.now();
                  cubit.setStartTime(
                    DateTime(now.year, now.month, now.day, time.hour,
                        time.minute),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_filled,
                  color: AppColors.primary),
              title: const Text('End Time'),
              subtitle: Text(
                state.endTime != null
                    ? timeFormat.format(state.endTime!)
                    : 'Select end time',
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: state.endTime != null
                      ? TimeOfDay.fromDateTime(state.endTime!)
                      : TimeOfDay.now(),
                );
                if (time != null) {
                  final now = DateTime.now();
                  cubit.setEndTime(
                    DateTime(now.year, now.month, now.day, time.hour,
                        time.minute),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleSelector extends StatelessWidget {
  final BookingCreateState state;

  const _VehicleSelector({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingCreateCubit>();
    final compatibleVehicles = state.compatibleVehicles;
    final requiredType = state.slot?.slotType ?? 'vehicle';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Vehicle',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'This slot accepts only ${requiredType.toUpperCase()} vehicles.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            if (state.vehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'No vehicles found. Add a vehicle first.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/vehicles'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Vehicle'),
                    ),
                  ],
                ),
              )
            else if (compatibleVehicles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      'No ${requiredType.toUpperCase()} vehicle found. Add one in Settings to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/vehicles'),
                      icon: const Icon(Icons.add),
                      label: Text('Add ${requiredType.toUpperCase()} Vehicle'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: state.selectedVehicleId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.directions_car),
                  hintText: 'Choose a vehicle',
                ),
                items: compatibleVehicles.map((v) {
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      '${v.registrationNo} • ${v.vehicleType.toUpperCase()}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) cubit.selectVehicle(value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final BookingCreateState state;

  const _AmountDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    final amount = state.estimatedAmount;

    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Estimated Amount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              amount != null ? '\u20B9${amount.toStringAsFixed(2)}' : '--',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
