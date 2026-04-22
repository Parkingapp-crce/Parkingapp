import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../cubits/slots_cubit.dart';

class SocietyDetailScreen extends StatelessWidget {
  final String societyId;
  final String? bookingDate;
  final String? startTime;
  final String? endTime;
  final String? vehicleType;

  const SocietyDetailScreen({
    super.key,
    required this.societyId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SlotsCubit(GetIt.instance<ApiClient>())
        ..loadSocietyDetail(
          societyId,
          bookingDate: bookingDate,
          startTime: startTime,
          endTime: endTime,
          vehicleType: vehicleType,
        ),
      child: _SocietyDetailContent(
        societyId: societyId,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
        vehicleType: vehicleType,
      ),
    );
  }
}

class _SocietyDetailContent extends StatelessWidget {
  final String societyId;
  final String? bookingDate;
  final String? startTime;
  final String? endTime;
  final String? vehicleType;

  const _SocietyDetailContent({
    required this.societyId,
    this.bookingDate,
    this.startTime,
    this.endTime,
    this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(state.society?.name ?? 'Society Details')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SlotsState state) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading slots...');
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => context.read<SlotsCubit>().loadSocietyDetail(
          societyId,
          bookingDate: bookingDate,
          startTime: startTime,
          endTime: endTime,
          vehicleType: vehicleType,
        ),
      );
    }

    final society = state.society;
    if (society == null) {
      return const EmptyStateWidget(title: 'Society not found');
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SlotsCubit>().loadSocietyDetail(
        societyId,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
        vehicleType: vehicleType,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SocietyHeader(
              society: society,
              matchingSlots: state.hasAvailabilityContext
                  ? state.slots.length
                  : null,
            ),
          ),
          if (state.hasAvailabilityContext)
            SliverToBoxAdapter(
              child: _AvailabilitySummaryCard(
                bookingDate: state.bookingDate!,
                startTime: state.startTime!,
                endTime: state.endTime!,
                vehicleType: state.vehicleType!,
              ),
            )
          else
            const SliverToBoxAdapter(child: _FilterBar()),
          _buildSlotsList(context, state),
        ],
      ),
    );
  }

  Widget _buildSlotsList(BuildContext context, SlotsState state) {
    final slots = state.filteredSlots;

    if (slots.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.grid_view_outlined,
          title: 'No slots found',
          subtitle: state.hasAvailabilityContext
              ? 'This society does not have a valid slot for the selected time window anymore.'
              : 'Try adjusting your filters.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _SlotTile(
            slot: slots[index],
            societyId: societyId,
            bookingDate: state.bookingDate,
            startTime: state.startTime,
            endTime: state.endTime,
          );
        }, childCount: slots.length),
      ),
    );
  }
}

class _SocietyHeader extends StatelessWidget {
  final SocietyModel society;
  final int? matchingSlots;

  const _SocietyHeader({required this.society, this.matchingSlots});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${society.address}, ${society.city}, ${society.state} - ${society.pincode}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                society.contactPhone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  society.contactEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: 'Total: ${society.totalSlots ?? 0}',
                color: AppColors.primary,
              ),
              _InfoChip(
                label: matchingSlots != null
                    ? 'Matching: $matchingSlots'
                    : 'Available: ${society.availableSlots ?? 0}',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySummaryCard extends StatelessWidget {
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String vehicleType;

  const _AvailabilitySummaryCard({
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(bookingDate);
    final startDateTime = _parseDateTime(bookingDate, startTime);
    final endDateTime = _parseDateTime(bookingDate, endTime);
    final dateLabel = date != null
        ? DateFormat('EEE, MMM d, yyyy').format(date)
        : bookingDate;
    final timeLabel = startDateTime != null && endDateTime != null
        ? '${DateFormat('hh:mm a').format(startDateTime)} - ${DateFormat('hh:mm a').format(endDateTime)}'
        : '$startTime - $endTime';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Showing slots for your selected booking window',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: dateLabel, color: AppColors.primary),
              _InfoChip(label: timeLabel, color: AppColors.primary),
              _InfoChip(
                label: vehicleType.toUpperCase(),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime? _parseDateTime(String date, String time) {
    return DateTime.tryParse('${date}T${_normalizeTime(time)}');
  }

  String _normalizeTime(String value) {
    return value.length == 5 ? '$value:00' : value;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Type: ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              _FilterChip(
                label: 'All',
                selected: state.filterType == null,
                onTap: () => context.read<SlotsCubit>().setFilterType(null),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Car',
                selected: state.filterType == 'car',
                onTap: () => context.read<SlotsCubit>().setFilterType('car'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Bike',
                selected: state.filterType == 'bike',
                onTap: () => context.read<SlotsCubit>().setFilterType('bike'),
              ),
              const SizedBox(width: 16),
              const Text(
                'State: ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              _FilterChip(
                label: 'All',
                selected: state.filterState == null,
                onTap: () => context.read<SlotsCubit>().setFilterState(null),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Available',
                selected: state.filterState == 'available',
                onTap: () =>
                    context.read<SlotsCubit>().setFilterState('available'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Occupied',
                selected: state.filterState == 'occupied',
                onTap: () =>
                    context.read<SlotsCubit>().setFilterState('occupied'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Reserved',
                selected: state.filterState == 'reserved',
                onTap: () =>
                    context.read<SlotsCubit>().setFilterState('reserved'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final SlotModel slot;
  final String societyId;
  final String? bookingDate;
  final String? startTime;
  final String? endTime;

  const _SlotTile({
    required this.slot,
    required this.societyId,
    this.bookingDate,
    this.startTime,
    this.endTime,
  });

  Color get _stateColor {
    switch (slot.state) {
      case 'available':
        return AppColors.slotAvailable;
      case 'reserved':
        return AppColors.slotReserved;
      case 'occupied':
        return AppColors.slotOccupied;
      case 'blocked':
        return AppColors.slotBlocked;
      default:
        return AppColors.slotBlocked;
    }
  }

  IconData get _typeIcon {
    return slot.slotType == 'bike' ? Icons.two_wheeler : Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slot.isAvailable
          ? () {
              final uri = Uri(
                path: '/booking/create',
                queryParameters: {
                  'societyId': societyId,
                  'slotId': slot.id,
                  ...?bookingDate == null ? null : {'bookingDate': bookingDate},
                  ...?startTime == null ? null : {'startTime': startTime},
                  ...?endTime == null ? null : {'endTime': endTime},
                },
              );
              context.push(uri.toString());
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _stateColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _stateColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_typeIcon, color: _stateColor, size: 26),
            const SizedBox(height: 8),
            Text(
              slot.slotNumber,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _stateColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              slot.state.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _stateColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\u20B9${slot.hourlyRate}/hr',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _stateColor,
              ),
            ),
            if (slot.floor.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Floor ${slot.floor}',
                style: TextStyle(
                  fontSize: 10,
                  color: _stateColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
