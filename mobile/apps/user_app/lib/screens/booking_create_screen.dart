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
  final String? bookingDate;
  final String? startTime;
  final String? endTime;

  const BookingCreateScreen({
    super.key,
    required this.societyId,
    required this.slotId,
    this.bookingDate,
    this.startTime,
    this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BookingCreateCubit(GetIt.instance<ApiClient>())..initialize(
            societyId: societyId,
            slotId: slotId,
            bookingDate: bookingDate,
            startTime: startTime,
            endTime: endTime,
          ),
      child: const _BookingCreateContent(),
    );
  }
}

class _BookingCreateContent extends StatelessWidget {
  const _BookingCreateContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Slot')),
      body: BlocConsumer<BookingCreateCubit, BookingCreateState>(
        listener: (context, state) {
          if (state.createdBooking != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking created successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/bookings/${state.createdBooking!.id}?autoPay=true');
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
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
                _CheckoutGradientButton(
                  label: 'Proceed to Checkout',
                  isLoading: state.isCreating,
                  onPressed: () =>
                      context.read<BookingCreateCubit>().createBooking(),
                  icon: Icons.payment_rounded,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Slot Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.grid_view_rounded,
            label: 'Slot Number',
            value: slot.slotNumber,
          ),
          if (society != null)
            _InfoRow(
              icon: Icons.apartment_rounded,
              label: 'Society',
              value: society.name,
            ),
          _InfoRow(
            icon: slot.slotType == 'bike'
                ? Icons.two_wheeler_rounded
                : Icons.directions_car_rounded,
            label: 'Type',
            value: slot.slotType.toUpperCase(),
          ),
          if (slot.floor.isNotEmpty)
            _InfoRow(icon: Icons.layers_rounded, label: 'Floor', value: slot.floor),
          _InfoRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Hourly Rate',
            value: '₹${slot.hourlyRate}/hr',
          ),
          if (slot.availableFrom != null && slot.availableTo != null)
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Availability',
              value: '${slot.availableFrom} - ${slot.availableTo}',
            ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Inter',
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
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    if (state.hasPresetWindow) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Window',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: state.startDate != null
                  ? dateFormat.format(state.startDate!)
                  : '--',
            ),
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Time',
              value: state.startTime != null && state.endTime != null
                  ? '${timeFormat.format(state.startTime!)} - ${timeFormat.format(state.endTime!)}'
                  : '--',
            ),
            const SizedBox(height: 8),
            Text(
              'This booking uses the slot availability window you selected in search.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                  ),
            ),
          ],
        ),
      );
    }

    final cubit = context.read<BookingCreateCubit>();

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
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
              'Date',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            subtitle: Text(
              state.startDate != null
                  ? dateFormat.format(state.startDate!)
                  : 'Select date',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
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
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Start Time',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            subtitle: Text(
              state.startTime != null
                  ? timeFormat.format(state.startTime!)
                  : 'Select start time',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
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
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
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
              'End Time',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            subtitle: Text(
              state.endTime != null
                  ? timeFormat.format(state.endTime!)
                  : 'Select end time',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'Inter',
              ),
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
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  ),
                );
              }
            },
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Vehicle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This slot accepts only ${requiredType.toUpperCase()} vehicles.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Inter',
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/vehicles'),
                    icon: const Icon(Icons.add_rounded),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontFamily: 'Inter',
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/vehicles'),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add ${requiredType.toUpperCase()} Vehicle'),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: state.selectedVehicleId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.directions_car_rounded),
                hintText: 'Choose a vehicle',
              ),
              items: compatibleVehicles.map((v) {
                return DropdownMenuItem(
                  value: v.id,
                  child: Text(
                    '${v.registrationNo} (${v.vehicleType.toUpperCase()})',
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) cubit.selectVehicle(value);
              },
            ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estimated Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '*Dynamic surge pricing may apply at checkout based on society occupancy and location.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontFamily: 'Inter',
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            amount != null ? '₹${amount.toStringAsFixed(2)}*' : '--',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _CheckoutGradientButton({
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
