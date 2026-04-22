import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SocietyLocationPickerScreen extends StatefulWidget {
  final LocationSuggestionModel? initialLocation;

  const SocietyLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<SocietyLocationPickerScreen> createState() =>
      _SocietyLocationPickerScreenState();
}

class _SocietyLocationPickerScreenState
    extends State<SocietyLocationPickerScreen> {
  static const _defaultCenter = LatLng(20.5937, 78.9629);

  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialLocation != null
        ? LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin Society Location')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: widget.initialLocation != null ? 16 : 5,
                onTap: (_, point) {
                  setState(() {
                    _selectedPoint = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.parkease.super_admin_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap the map to place the society pin.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)}  |  Lng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Confirm Society Location',
                  icon: Icons.check_circle_outline,
                  onPressed: () => Navigator.of(context).pop(_selectedPoint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
