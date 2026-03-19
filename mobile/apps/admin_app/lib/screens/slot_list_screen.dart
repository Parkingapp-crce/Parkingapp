import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/slots_cubit.dart';

class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  String? get _societyId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  void _loadSlots() {
    final societyId = _societyId;
    if (societyId != null) {
      context.read<SlotsCubit>().loadSlots(societyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlots,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/slots/create'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<SlotsCubit, SlotsState>(
              builder: (context, state) {
                if (state.isLoading && state.slots.isEmpty) {
                  return const LoadingWidget(message: 'Loading slots...');
                }

                if (state.error != null && state.slots.isEmpty) {
                  return AppErrorWidget(
                    message: state.error!,
                    onRetry: _loadSlots,
                  );
                }

                final slots = state.filteredSlots;

                if (slots.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.local_parking,
                    title: 'No slots found',
                    subtitle: 'Add a new parking slot to get started',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadSlots(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      return _SlotCard(
                        slot: slots[index],
                        onTap: () => context.go('/slots/${slots[index].id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: state.stateFilter == null,
                onSelected: () {
                  context.read<SlotsCubit>().setStateFilter(null);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Available',
                selected: state.stateFilter == 'available',
                color: AppColors.slotAvailable,
                onSelected: () {
                  context.read<SlotsCubit>().setStateFilter('available');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Reserved',
                selected: state.stateFilter == 'reserved',
                color: AppColors.slotReserved,
                onSelected: () {
                  context.read<SlotsCubit>().setStateFilter('reserved');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Occupied',
                selected: state.stateFilter == 'occupied',
                color: AppColors.slotOccupied,
                onSelected: () {
                  context.read<SlotsCubit>().setStateFilter('occupied');
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Blocked',
                selected: state.stateFilter == 'blocked',
                color: AppColors.slotBlocked,
                onSelected: () {
                  context.read<SlotsCubit>().setStateFilter('blocked');
                },
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 24,
                color: AppColors.divider,
              ),
              const SizedBox(width: 16),
              _FilterChip(
                label: 'Car',
                selected: state.typeFilter == 'car',
                onSelected: () {
                  final cubit = context.read<SlotsCubit>();
                  if (state.typeFilter == 'car') {
                    cubit.setTypeFilter(null);
                  } else {
                    cubit.setTypeFilter('car');
                  }
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Bike',
                selected: state.typeFilter == 'bike',
                onSelected: () {
                  final cubit = context.read<SlotsCubit>();
                  if (state.typeFilter == 'bike') {
                    cubit.setTypeFilter(null);
                  } else {
                    cubit.setTypeFilter('bike');
                  }
                },
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
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color?.withOpacity(0.2) ?? AppColors.primaryLight,
      checkmarkColor: color ?? AppColors.primary,
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback onTap;

  const _SlotCard({
    required this.slot,
    required this.onTap,
  });

  Color _stateColor() {
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
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              slot.slotType == 'bike'
                  ? Icons.two_wheeler
                  : Icons.directions_car,
              color: stateColor,
            ),
          ),
        ),
        title: Text(
          'Slot ${slot.slotNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Floor: ${slot.floor.isNotEmpty ? slot.floor : '-'} | '
          '${slot.slotType.toUpperCase()} | '
          '\u20B9${slot.hourlyRate}/hr',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: stateColor.withOpacity(0.3)),
          ),
          child: Text(
            slot.state.toUpperCase(),
            style: TextStyle(
              color: stateColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
