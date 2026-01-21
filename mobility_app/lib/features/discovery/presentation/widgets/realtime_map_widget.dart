import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/entities/nearby_user.dart';

/// Real-time map widget with live location tracking and user markers
///
/// Features:
/// - Current user location with blue marker
/// - Nearby drivers/passengers with custom colored markers
/// - Real-time position updates
/// - Custom marker icons by vehicle type
/// - Automatic camera following
class RealTimeMapWidget extends StatefulWidget {
  /// Current user's ID
  final String currentUserId;

  /// List of nearby users to display on map
  final List<NearbyUser> nearbyUsers;

  /// Whether to follow current user's location
  final bool followUser;

  /// Initial camera zoom level
  final double initialZoom;

  /// Callback when a user marker is tapped
  final void Function(NearbyUser user)? onUserTapped;

  /// Callback when map is tapped (not on a marker)
  final void Function(LatLng position)? onMapTapped;

  /// Location service instance
  final LocationServiceImpl? locationService;

  const RealTimeMapWidget({
    required this.currentUserId,
    this.nearbyUsers = const [],
    this.followUser = true,
    this.initialZoom = 14.0,
    this.onUserTapped,
    this.onMapTapped,
    this.locationService,
    super.key,
  });

  @override
  State<RealTimeMapWidget> createState() => _RealTimeMapWidgetState();
}

class _RealTimeMapWidgetState extends State<RealTimeMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isInitialized = false;

  // Marker colors by role/vehicle type
  static const _markerColors = {
    'driver_moto': BitmapDescriptor.hueGreen,
    'driver_cab': BitmapDescriptor.hueOrange,
    'driver_liffan': BitmapDescriptor.hueYellow,
    'driver_truck': BitmapDescriptor.hueRed,
    'driver': BitmapDescriptor.hueRed,
    'passenger': BitmapDescriptor.hueViolet,
    'current': BitmapDescriptor.hueAzure,
  };

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(RealTimeMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update markers if nearby users changed
    if (oldWidget.nearbyUsers != widget.nearbyUsers) {
      _updateNearbyUserMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      final locationService = widget.locationService ?? LocationServiceImpl();
      _currentPosition = await locationService.getCurrentPosition();

      if (_currentPosition != null && mounted) {
        // Add current user marker
        _addCurrentUserMarker();

        // Add nearby user markers
        _updateNearbyUserMarkers();

        // Start location tracking
        _startLocationTracking(locationService);

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize map: $e');
    }
  }

  void _startLocationTracking(LocationServiceImpl locationService) {
    _positionSubscription?.cancel();
    
    _positionSubscription = locationService.getAdaptivePositionStream().listen(
      (position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          _addCurrentUserMarker();

          // Follow user if enabled
          if (widget.followUser) {
            _animateCameraToPosition(position);
          }
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void _addCurrentUserMarker() {
    if (_currentPosition == null) return;

    final marker = Marker(
      markerId: MarkerId(widget.currentUserId),
      position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      infoWindow: const InfoWindow(title: 'You'),
      icon: BitmapDescriptor.defaultMarkerWithHue(_markerColors['current']!),
      anchor: const Offset(0.5, 0.5),
      zIndexInt: 2, // Higher z-index to show on top
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == widget.currentUserId);
      _markers.add(marker);
    });
  }

  void _updateNearbyUserMarkers() {
    // Remove old nearby user markers (keep current user marker)
    _markers.removeWhere((m) => m.markerId.value != widget.currentUserId);

    // Add new markers for nearby users
    for (final user in widget.nearbyUsers) {
      if (user.latitude == null || user.longitude == null) continue;

      final markerKey = _getMarkerKey(user);
      final hue = _markerColors[markerKey] ?? BitmapDescriptor.hueRed;

      final marker = Marker(
        markerId: MarkerId(user.id),
        position: LatLng(user.latitude!, user.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: user.name,
          snippet: _buildMarkerSnippet(user),
        ),
        onTap: () => widget.onUserTapped?.call(user),
        zIndexInt: 1,
      );

      _markers.add(marker);
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _getMarkerKey(NearbyUser user) {
    if (user.role == 'driver' && user.vehicleCategory != null) {
      return 'driver_${user.vehicleCategory!.toLowerCase()}';
    }
    return user.role;
  }

  String _buildMarkerSnippet(NearbyUser user) {
    final parts = <String>[];
    
    if (user.vehicleCategory != null) {
      parts.add(user.vehicleCategory!);
    }
    
    parts.add('${user.rating.toStringAsFixed(1)} ★');
    parts.add('${user.distanceKm.toStringAsFixed(1)} km');
    
    return parts.join(' • ');
  }

  void _animateCameraToPosition(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  void _fitAllMarkers() {
    if (_markers.length < 2) return;

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final marker in _markers) {
      final pos = marker.position;
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _currentPosition == null) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: widget.initialZoom,
          ),
          markers: _markers,
          myLocationEnabled: false, // We use custom marker
          myLocationButtonEnabled: false,
          compassEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: widget.onMapTapped,
        ),

        // Map controls overlay
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Fit all markers button
              if (_markers.length > 1)
                _MapControlButton(
                  icon: Icons.fit_screen,
                  onTap: _fitAllMarkers,
                  tooltip: 'Fit all markers',
                ),
              const SizedBox(height: 8),
              // Center on me button
              _MapControlButton(
                icon: Icons.my_location,
                onTap: () {
                  if (_currentPosition != null) {
                    _animateCameraToPosition(_currentPosition!);
                  }
                },
                tooltip: 'Center on me',
              ),
            ],
          ),
        ),

        // Legend
        Positioned(
          left: 16,
          bottom: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading map...'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: Colors.blue, label: 'You'),
          _LegendItem(color: Colors.green, label: 'Moto'),
          _LegendItem(color: Colors.orange, label: 'Cab'),
          _LegendItem(color: Colors.purple, label: 'Passenger'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}

/// Map control button widget
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Legend item for map markers
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
