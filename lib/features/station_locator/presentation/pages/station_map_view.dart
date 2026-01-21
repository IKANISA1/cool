import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/station_marker.dart';
import '../bloc/station_locator_bloc.dart';
import '../bloc/station_locator_event.dart';
import '../bloc/station_locator_state.dart';
import '../utils/map_styles.dart';
import '../widgets/station_bottom_sheet.dart';

/// Google Maps view for displaying stations
///
/// Features:
/// - Custom marker icons based on availability
/// - Bottom sheet for station quick info
/// - Navigation integration with Google Maps
/// - Dark/light mode support
class StationMapView extends StatefulWidget {
  /// Type of stations to display: 'battery_swap', 'ev_charging', or 'all'
  final String stationType;

  const StationMapView({
    super.key,
    required this.stationType,
  });

  @override
  State<StationMapView> createState() => _StationMapViewState();
}

class _StationMapViewState extends State<StationMapView> {
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  List<StationMarker> _stationMarkers = [];

  // Default camera position (Kigali, Rwanda)
  static const LatLng _defaultPosition = LatLng(-1.9441, 30.0619);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Build markers from station list
  Future<void> _buildMarkers(List<StationMarker> stations) async {
    final Set<Marker> markers = {};

    for (final station in stations) {
      final marker = Marker(
        markerId: MarkerId(station.id),
        position: station.position,
        icon: await _getMarkerIcon(station),
        onTap: () => _onStationTap(station),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: station.brand ?? station.network ?? '',
        ),
      );
      markers.add(marker);
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  /// Get marker icon based on station type and availability
  Future<BitmapDescriptor> _getMarkerIcon(StationMarker station) async {
    // Use colored hue markers based on availability
    double hue;
    if (!station.isOperational) {
      hue = BitmapDescriptor.hueRose;
    } else if (station.availabilityPercent == null) {
      hue = BitmapDescriptor.hueYellow;
    } else if (station.availabilityPercent! >= 75) {
      hue = BitmapDescriptor.hueGreen;
    } else if (station.availabilityPercent! >= 50) {
      hue = BitmapDescriptor.hueOrange;
    } else {
      hue = BitmapDescriptor.hueRed;
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  /// Handle station tap - show bottom sheet
  void _onStationTap(StationMarker station) {
    HapticFeedback.mediumImpact();

    // Update bloc state
    context.read<StationLocatorBloc>().add(
          SelectStation(stationId: station.id),
        );

    // Show bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => StationBottomSheet(
        station: station,
        onNavigate: () => _navigateToStation(station),
        onViewDetails: () {
          Navigator.pop(context);
          // TODO: Navigate to station details page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Details for ${station.displayName}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  /// Open Google Maps for navigation to station
  Future<void> _navigateToStation(StationMarker station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.position.latitude},${station.position.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Center map on user's current location
  Future<void> _goToMyLocation() async {
    HapticFeedback.mediumImpact();

    try {
      final position = await context
          .read<StationLocatorBloc>()
          .locationService
          .getCurrentPosition();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Fit map bounds to show all stations
  void _fitBoundsToMarkers(List<StationMarker> markers) {
    if (markers.isEmpty) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  /// Set map style based on brightness
  void _setMapStyle(GoogleMapController controller, Brightness brightness) {
    final style =
        brightness == Brightness.dark ? MapStyles.darkMode : MapStyles.lightMode;
    // Note: setMapStyle is deprecated but still works for now
    controller.setMapStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return BlocConsumer<StationLocatorBloc, StationLocatorState>(
      listener: (context, state) {
        if (state is StationLocatorLoaded) {
          // Update markers with stations
          setState(() {
            _stationMarkers = state.stations;
          });

          // Build markers
          _buildMarkers(state.stations);

          // Fit bounds to show all stations
          if (state.stations.isNotEmpty && _mapController != null) {
            // Delay to allow markers to build
            Future.delayed(const Duration(milliseconds: 300), () {
              _fitBoundsToMarkers(state.stations);
            });
          }
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultPosition,
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _setMapStyle(controller, brightness);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // Custom button below
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
            ),

            // Loading indicator
            if (state is StationLocatorLoading)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading stations...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Station count badge
            if (state is StationLocatorLoaded && _stationMarkers.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      '${_stationMarkers.length} ${widget.stationType == 'battery_swap' ? 'Battery Swap' : widget.stationType == 'ev_charging' ? 'Charging' : ''} Stations',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

            // Error message
            if (state is StationLocatorError)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.message)),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            context.read<StationLocatorBloc>().add(
                                  LoadNearbyStations(
                                      stationType: widget.stationType),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Refresh button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'refresh',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.read<StationLocatorBloc>().add(
                        LoadNearbyStations(stationType: widget.stationType),
                      );
                },
                tooltip: 'Refresh',
                child: const Icon(Icons.refresh),
              ),
            ),

            // My location button
            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _goToMyLocation,
                tooltip: 'My Location',
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        );
      },
    );
  }
}
