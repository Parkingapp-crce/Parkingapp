import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../cubits/slots_cubit.dart';

class SlotFormScreen extends StatefulWidget {
  final String? slotId;

  const SlotFormScreen({super.key, this.slotId});

  @override
  State<SlotFormScreen> createState() => _SlotFormScreenState();
}

class _SlotFormScreenState extends State<SlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _slotNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  String _slotType = 'car';
  String _ownershipType = 'society';
  bool _isSubmitting = false;

  bool get isEditing => widget.slotId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final slot = context.read<SlotsCubit>().getSlotById(widget.slotId!);
    if (slot != null) {
      _slotNumberController.text = slot.slotNumber;
      _floorController.text = slot.floor;
      _hourlyRateController.text = slot.hourlyRate;
      setState(() {
        _slotType = slot.slotType;
        _ownershipType = slot.ownershipType;
      });
    }
  }

  @override
  void dispose() {
    _slotNumberController.dispose();
    _floorController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  String? get _societyId {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.society;
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final societyId = _societyId;
    if (societyId == null) return;

    setState(() => _isSubmitting = true);

    final data = {
      'slot_number': _slotNumberController.text.trim(),
      'floor': _floorController.text.trim(),
      'slot_type': _slotType,
      'hourly_rate': _hourlyRateController.text.trim(),
      'ownership_type': _ownershipType,
    };

    try {
      if (isEditing) {
        await context.read<SlotsCubit>().updateSlot(
              societyId,
              widget.slotId!,
              data,
            );
      } else {
        await context.read<SlotsCubit>().createSlot(societyId, data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Slot updated' : 'Slot created'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<SlotsCubit>().state.error ?? 'An error occurred',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Slot' : 'Create Slot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _slotNumberController,
                label: 'Slot Number',
                hint: 'e.g. A-101',
                prefixIcon: Icons.tag,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a slot number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _floorController,
                label: 'Floor',
                hint: 'e.g. Ground, 1, 2',
                prefixIcon: Icons.layers,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _slotType,
                decoration: const InputDecoration(
                  labelText: 'Slot Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'car', child: Text('Car')),
                  DropdownMenuItem(value: 'bike', child: Text('Bike')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _slotType = value);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _hourlyRateController,
                label: 'Hourly Rate (\u20B9)',
                hint: 'e.g. 50.00',
                prefixIcon: Icons.currency_rupee,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the hourly rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _ownershipType,
                decoration: const InputDecoration(
                  labelText: 'Ownership Type',
                  prefixIcon: Icon(Icons.business),
                ),
                items: const [
                  DropdownMenuItem(value: 'society', child: Text('Society')),
                  DropdownMenuItem(value: 'resident', child: Text('Resident')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _ownershipType = value);
                },
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: isEditing ? 'Update Slot' : 'Create Slot',
                onPressed: _onSubmit,
                isLoading: _isSubmitting,
                icon: isEditing ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
