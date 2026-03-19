import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:core/core.dart';

import '../cubits/vehicles_cubit.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VehiclesCubit(GetIt.instance<ApiClient>())..loadVehicles(),
      child: const _VehiclesContent(),
    );
  }
}

class _VehiclesContent extends StatelessWidget {
  const _VehiclesContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<VehiclesCubit, VehiclesState>(
        listener: (context, state) {
          if (state.addSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vehicle added successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
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
            return const LoadingWidget(message: 'Loading vehicles...');
          }

          if (state.vehicles.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles added',
              subtitle: 'Add a vehicle to start booking parking slots',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<VehiclesCubit>().loadVehicles(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.vehicles.length,
              itemBuilder: (context, index) {
                return _VehicleCard(vehicle: state.vehicles[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final regController = TextEditingController();
    final makeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedType = 'car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Add Vehicle',
                      style: Theme.of(sheetContext)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'car', child: Text('Car')),
                        DropdownMenuItem(value: 'bike', child: Text('Bike')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: regController,
                      label: 'Registration Number',
                      hint: 'e.g., MH01AB1234',
                      prefixIcon: Icons.confirmation_number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Registration number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: makeController,
                      label: 'Make & Model',
                      hint: 'e.g., Honda City',
                      prefixIcon: Icons.info_outline,
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<VehiclesCubit, VehiclesState>(
                      builder: (_, vState) {
                        return PrimaryButton(
                          label: 'Add Vehicle',
                          isLoading: vState.isAdding,
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            context.read<VehiclesCubit>().addVehicle(
                                  vehicleType: selectedType,
                                  registrationNo:
                                      regController.text.trim(),
                                  makeModel:
                                      makeController.text.trim(),
                                );
                            Navigator.of(sheetContext).pop();
                          },
                          icon: Icons.add,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                vehicle.vehicleType == 'bike'
                    ? Icons.two_wheeler
                    : Icons.directions_car,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.registrationNo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${vehicle.vehicleType.toUpperCase()}${vehicle.makeModel.isNotEmpty ? ' - ${vehicle.makeModel}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            if (vehicle.isActive)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _showDeleteDialog(context, vehicle),
              ),
            if (!vehicle.isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VehicleModel vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to remove ${vehicle.registrationNo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<VehiclesCubit>().deleteVehicle(vehicle.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
