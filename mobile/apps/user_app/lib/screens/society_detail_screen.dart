import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/slots_cubit.dart';

class SocietyDetailScreen extends StatelessWidget {
  final String societyId;

  const SocietyDetailScreen({super.key, required this.societyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SlotsCubit(GetIt.instance<ApiClient>())..loadSocietyDetail(societyId),
      child: _SocietyDetailContent(societyId: societyId),
    );
  }
}

class _SocietyDetailContent extends StatelessWidget {
  final String societyId;

  const _SocietyDetailContent({required this.societyId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state.society?.name ?? 'Society Details'),
          ),
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
        onRetry: () =>
            context.read<SlotsCubit>().loadSocietyDetail(societyId),
      );
    }

    final society = state.society;
    if (society == null) {
      return const EmptyStateWidget(
        title: 'Society not found',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SlotsCubit>().loadSocietyDetail(societyId),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SocietyHeader(society: society),
          ),
          SliverToBoxAdapter(
            child: _FilterBar(),
          ),
          _buildSlotsList(context, state),
        ],
      ),
    );
  }

  Widget _buildSlotsList(BuildContext context, SlotsState state) {
    final slots = state.filteredSlots;

    if (slots.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.grid_view_outlined,
          title: 'No slots found',
          subtitle: 'Try adjusting your filters',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _SlotTile(
              slot: slots[index],
              societyId: societyId,
            );
          },
          childCount: slots.length,
        ),
      ),
    );
  }
}

class _SocietyHeader extends StatelessWidget {
  final SocietyModel society;

  const _SocietyHeader({required this.society});

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
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textSecondary),
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
              const Icon(Icons.phone_outlined,
                  size: 18, color: AppColors.textSecondary),
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
              const Icon(Icons.email_outlined,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                society.contactEmail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                label: 'Total: ${society.totalSlots ?? 0}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Available: ${society.availableSlots ?? 0}',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Type: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
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
              const Text('State: ',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary)),
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

  const _SlotTile({required this.slot, required this.societyId});

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
    return slot.slotType == 'bike'
        ? Icons.two_wheeler
        : Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: slot.isAvailable
          ? () {
              context.push(
                '/booking/create?societyId=$societyId&slotId=${slot.id}',
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _stateColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _stateColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_typeIcon, color: _stateColor, size: 24),
            const SizedBox(height: 4),
            Text(
              slot.slotNumber,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _stateColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot.state.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: _stateColor,
              ),
            ),
            if (slot.floor.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'F${slot.floor}',
                style: TextStyle(
                  fontSize: 9,
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
