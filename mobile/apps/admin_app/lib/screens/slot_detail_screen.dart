import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/slots_cubit.dart';

class SlotDetailScreen extends StatelessWidget {
  final String slotId;

  const SlotDetailScreen({super.key, required this.slotId});

  String? _getSocietyId(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  Color _stateColor(String state) {
    switch (state) {
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
    return BlocBuilder<SlotsCubit, SlotsState>(
      builder: (context, state) {
        final slot = context.read<SlotsCubit>().getSlotById(slotId);

        if (slot == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Slot Details')),
            body: const AppErrorWidget(message: 'Slot not found'),
          );
        }

        final stateColor = _stateColor(slot.state);

        return Scaffold(
          appBar: AppBar(
            title: Text('Slot ${slot.slotNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/slots/$slotId/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // State banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: stateColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stateColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Icon(
                      slot.slotType == 'bike'
                          ? Icons.two_wheeler
                          : Icons.directions_car,
                      size: 48,
                      color: stateColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slot.state.toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slot Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Slot Number',
                        value: slot.slotNumber,
                      ),
                      _DetailRow(
                        label: 'Floor',
                        value: slot.floor.isNotEmpty ? slot.floor : '-',
                      ),
                      _DetailRow(
                        label: 'Type',
                        value: slot.slotType.toUpperCase(),
                      ),
                      _DetailRow(
                        label: 'Hourly Rate',
                        value: '\u20B9${slot.hourlyRate}',
                      ),
                      _DetailRow(
                        label: 'Ownership',
                        value: slot.ownershipType.toUpperCase(),
                      ),
                      _DetailRow(
                        label: 'Active',
                        value: slot.isActive ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Block/Unblock button
              if (slot.isBlocked)
                PrimaryButton(
                  label: 'Unblock Slot',
                  icon: Icons.lock_open,
                  onPressed: () async {
                    final societyId = _getSocietyId(context);
                    if (societyId != null) {
                      await context.read<SlotsCubit>().unblockSlot(
                            societyId,
                            slotId,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Slot unblocked'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                )
              else if (slot.isAvailable)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Block Slot'),
                          content: Text(
                            'Are you sure you want to block slot ${slot.slotNumber}? '
                            'It will not be available for booking.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Block'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final societyId = _getSocietyId(context);
                        if (societyId != null) {
                          await context.read<SlotsCubit>().blockSlot(
                                societyId,
                                slotId,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Slot blocked'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.block, color: AppColors.error),
                    label: const Text(
                      'Block Slot',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
