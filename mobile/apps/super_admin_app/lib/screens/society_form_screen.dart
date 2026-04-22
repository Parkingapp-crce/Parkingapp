import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../cubits/societies_cubit.dart';
import 'society_location_picker_screen.dart';

class SocietyFormScreen extends StatefulWidget {
  final String? societyId;

  const SocietyFormScreen({super.key, this.societyId});

  @override
  State<SocietyFormScreen> createState() => _SocietyFormScreenState();
}

class _SocietyFormScreenState extends State<SocietyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _adminFullNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  final List<LocationSuggestionModel> _locationSuggestions = [];

  Timer? _locationDebounce;
  LocationSuggestionModel? _selectedLocation;
  bool _isSubmitting = false;
  bool _isResolvingLocation = false;
  bool _obscureAdminPassword = true;

  double _roundCoordinate(double value) => double.parse(
    value.toStringAsFixed(6),
  );

  bool get isEditing => widget.societyId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final society = context.read<SocietiesCubit>().getSocietyById(
      widget.societyId!,
    );
    if (society == null) {
      return;
    }

    _nameController.text = society.name;
    _addressController.text = society.address;
    _cityController.text = society.city;
    _stateController.text = society.state;
    _pincodeController.text = society.pincode;
    _contactEmailController.text = society.contactEmail;
    _contactPhoneController.text = society.contactPhone;

    if (society.latitude != null && society.longitude != null) {
      final label =
          '${society.address}, ${society.city}, ${society.state} ${society.pincode}';
      _selectedLocation = LocationSuggestionModel(
        placeId: '',
        title: society.name,
        subtitle: label,
        label: label,
        latitude: society.latitude!,
        longitude: society.longitude!,
      );
      _locationSearchController.text = label;
    }
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _locationSearchController.dispose();
    _adminFullNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedLocation == null) {
      _showMessage('Select the society location from search or map.');
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'latitude': _roundCoordinate(_selectedLocation!.latitude),
      'longitude': _roundCoordinate(_selectedLocation!.longitude),
      'contact_email': _contactEmailController.text.trim(),
      'contact_phone': _contactPhoneController.text.trim(),
    };

    if (!isEditing) {
      data.addAll({
        'admin_full_name': _adminFullNameController.text.trim(),
        'admin_email': _adminEmailController.text.trim(),
        'admin_phone': _adminPhoneController.text.trim(),
        'admin_password': _adminPasswordController.text,
      });
    }

    try {
      if (isEditing) {
        await context.read<SocietiesCubit>().updateSociety(
          widget.societyId!,
          data,
        );
      } else {
        await context.read<SocietiesCubit>().createSociety(data);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Society updated' : 'Society created'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        context.read<SocietiesCubit>().state.error ?? 'An error occurred',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _searchLocationSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _locationSuggestions.clear();
      });
      return;
    }

    try {
      final suggestions = await context.read<SocietiesCubit>().searchLocations(
        trimmed,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _locationSuggestions
          ..clear()
          ..addAll(suggestions);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Could not fetch location suggestions.', isError: true);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final pickedPoint = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) =>
            SocietyLocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (!mounted || pickedPoint == null) {
      return;
    }

    setState(() => _isResolvingLocation = true);
    try {
      final location = await context.read<SocietiesCubit>().reverseGeocode(
        latitude: pickedPoint.latitude,
        longitude: pickedPoint.longitude,
      );
      if (!mounted || location == null) {
        return;
      }
      setState(() {
        _selectedLocation = location;
        _locationSearchController.text = location.label;
        _locationSuggestions.clear();
      });
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not resolve the pinned map location.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  void _onLocationChanged(String value) {
    if (_selectedLocation != null && value.trim() != _selectedLocation!.label) {
      setState(() {
        _selectedLocation = null;
      });
    }

    _locationDebounce?.cancel();
    _locationDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchLocationSuggestions(value),
    );
  }

  void _selectLocation(LocationSuggestionModel location) {
    setState(() {
      _selectedLocation = location;
      _locationSearchController.text = location.label;
      _locationSuggestions.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Society' : 'Create Society'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Society Name',
                hint: 'Enter society name',
                prefixIcon: Icons.apartment,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the society name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter full address',
                prefixIcon: Icons.location_on,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      prefixIcon: Icons.location_city,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      prefixIcon: Icons.map,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: 'Enter pincode',
                prefixIcon: Icons.pin,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the pincode';
                  }
                  if (value.length != 6) {
                    return 'Pincode must be 6 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Society Location',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for the society address or pin the exact spot on the map. These coordinates power user-side parking search.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationSearchController,
                onChanged: _onLocationChanged,
                decoration: InputDecoration(
                  labelText: 'Search Location',
                  hintText: 'Search society address or landmark',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _selectedLocation != null
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedLocation = null;
                              _locationSearchController.clear();
                              _locationSuggestions.clear();
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
              ),
              if (_locationSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: _locationSuggestions
                        .map(
                          (location) => ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(location.title),
                            subtitle: location.subtitle.isNotEmpty
                                ? Text(
                                    location.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _selectLocation(location),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isResolvingLocation ? null : _pickLocationOnMap,
                icon: _isResolvingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.map_outlined),
                label: const Text('Pin Society on Map'),
              ),
              if (_selectedLocation != null) ...[
                const SizedBox(height: 12),
                _LocationSummaryCard(location: _selectedLocation!),
              ],
              const SizedBox(height: 16),
              AppTextField(
                controller: _contactEmailController,
                label: 'Contact Email',
                hint: 'Enter contact email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _contactPhoneController,
                label: 'Contact Phone',
                hint: 'Enter contact phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact phone';
                  }
                  return null;
                },
              ),
              if (!isEditing) ...[
                const SizedBox(height: 24),
                Text(
                  'Society Admin Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'These credentials will be used in the admin app to manage slots for this society.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _adminFullNameController,
                  label: 'Admin Full Name',
                  hint: 'Enter society admin name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the admin name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _adminEmailController,
                  label: 'Admin Email',
                  hint: 'Enter admin email',
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the admin email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _adminPhoneController,
                  label: 'Admin Phone',
                  hint: 'Enter admin phone',
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the admin phone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _adminPasswordController,
                  label: 'Temporary Password',
                  hint: 'Set a temporary password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureAdminPassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureAdminPassword = !_obscureAdminPassword;
                      });
                    },
                    icon: Icon(
                      _obscureAdminPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a temporary password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: isEditing ? 'Update Society' : 'Create Society',
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

class _LocationSummaryCard extends StatelessWidget {
  final LocationSuggestionModel location;

  const _LocationSummaryCard({required this.location});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pinned Society Location',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(location.label),
          const SizedBox(height: 6),
          Text(
            'Lat ${location.latitude.toStringAsFixed(6)}  |  Lng ${location.longitude.toStringAsFixed(6)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
