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
  static const _minZoom = 3.0;
  static const _maxZoom = 19.0;

  final MapController _mapController = MapController();
  late LatLng _selectedPoint;
  double _currentZoom = 11.0;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialLocation != null
        ? LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : _defaultCenter;
    _currentZoom = widget.initialLocation != null ? 16.0 : 11.0;
  }

  void _zoomBy(double delta) {
    final nextZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    setState(() {
      _currentZoom = nextZoom;
    });
    _mapController.move(_selectedPoint, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pin Society Location')), 
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: _currentZoom,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (_, point) {
                      setState(() {
                        _selectedPoint = point;
                      });
                    },
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        _currentZoom = camera.zoom;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.parkease.admin_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.location_pin,
                            size: 42,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: _currentZoom >= _maxZoom
                              ? null
                              : () => _zoomBy(1),
                          icon: const Icon(Icons.add),
                        ),
                        const Divider(height: 1),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: _currentZoom <= _minZoom
                              ? null
                              : () => _zoomBy(-1),
                          icon: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_selectedPoint.latitude.toStringAsFixed(6)}  |  Lng: ${_selectedPoint.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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