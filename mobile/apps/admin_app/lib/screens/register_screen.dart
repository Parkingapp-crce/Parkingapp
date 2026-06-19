import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:latlong2/latlong.dart';

import 'society_location_picker_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _societyNameController = TextEditingController();
  final _societyAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  LocationSuggestionModel? _selectedLocation;
  bool _isPickingLocation = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _applyLocationDetails(LocationSuggestionModel location) {
    _societyAddressController.text =
        location.address.isNotEmpty ? location.address : location.label;
    _cityController.text = location.city;
    _stateController.text = location.state;
    _pincodeController.text = location.pincode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _societyNameController.dispose();
    _societyAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    setState(() {
      _isPickingLocation = true;
    });

    try {
      final pickedPoint = await Navigator.of(context).push<LatLng>(
        MaterialPageRoute(
          builder: (_) => SocietyLocationPickerScreen(
            initialLocation: _selectedLocation,
          ),
        ),
      );

      if (!mounted || pickedPoint == null) {
        return;
      }

      setState(() => _selectedLocation = null);

      try {
        final response = await context.read<ApiClient>().get(
          ApiEndpoints.destinationReverseGeocode,
          queryParameters: {
            'latitude': pickedPoint.latitude,
            'longitude': pickedPoint.longitude,
          },
        );
        if (!mounted) {
          return;
        }

        final location = LocationSuggestionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        setState(() {
          _selectedLocation = location;
          _applyLocationDetails(location);
        });
      } catch (_) {
        if (!mounted) {
          return;
        }

        final fallbackLocation = LocationSuggestionModel(
          placeId: '',
          latitude: pickedPoint.latitude,
          longitude: pickedPoint.longitude,
          label:
              '${pickedPoint.latitude.toStringAsFixed(6)}, ${pickedPoint.longitude.toStringAsFixed(6)}',
          title: 'Pinned Society Location',
          subtitle:
              'Lat ${pickedPoint.latitude.toStringAsFixed(6)} | Lng ${pickedPoint.longitude.toStringAsFixed(6)}',
        );
        setState(() {
          _selectedLocation = fallbackLocation;
          _applyLocationDetails(fallbackLocation);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingLocation = false;
        });
      }
    }
  }

  void _onRegister() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pin the society location on the map.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: 'society_admin',
        societyName: _societyNameController.text.trim(),
        societyAddress: _societyAddressController.text.trim(),
        societyCity: _cityController.text.trim(),
        societyState: _stateController.text.trim(),
        societyPincode: _pincodeController.text.trim(),
        societyLatitude: _selectedLocation!.latitude,
        societyLongitude: _selectedLocation!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Signup')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Society Admin Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pin the society on the map to set its exact coordinates.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    hint: 'Enter your phone number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (value.length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffix: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffix: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      child: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _societyNameController,
                    label: 'Society Name',
                    hint: 'Enter society name',
                    prefixIcon: Icons.apartment,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Society name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _societyAddressController,
                    label: 'Society Address',
                    hint: 'Auto-filled from the pin, edit if needed',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Society address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Auto-filled from the pin, edit if needed',
                    prefixIcon: Icons.location_city,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'City is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'Auto-filled from the pin, edit if needed',
                    prefixIcon: Icons.map_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'State is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _pincodeController,
                    label: 'Pincode',
                    hint: 'Auto-filled from the pin, edit if needed',
                    prefixIcon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pincode is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isPickingLocation ? null : _pickLocationOnMap,
                    icon: _isPickingLocation
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
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return PrimaryButton(
                        label: 'Create Admin Account',
                        onPressed: _onRegister,
                        isLoading: state is AuthLoading,
                        icon: Icons.how_to_reg,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ],
              ),
            ),
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
    return Card(
      color: Theme.of(context).colorScheme.tertiary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(location.subtitle),
            const SizedBox(height: 4),
            Text(
              'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
