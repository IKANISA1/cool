import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/battery_swap_station.dart';
import '../../domain/entities/ev_charging_station.dart';

/// Marker model for map display
///
/// Represents both battery swap and EV charging stations.
class StationMarker {
  /// Unique station identifier
  final String id;

  /// Station display name
  final String name;

  /// Type of station: 'battery_swap' or 'ev_charging'
  final String stationType;

  /// Geographic position
  final LatLng position;

  /// Brand (for battery swap) or null
  final String? brand;

  /// Network (for EV charging) or null
  final String? network;

  /// Availability percentage (0-100) or null if unknown
  final double? availabilityPercent;

  /// Average user rating (0-5)
  final double rating;

  /// Whether the station is currently operational
  final bool isOperational;

  /// Additional station details
  final Map<String, dynamic> details;

  StationMarker({
    required this.id,
    required this.name,
    required this.stationType,
    required this.position,
    this.brand,
    this.network,
    this.availabilityPercent,
    required this.rating,
    required this.isOperational,
    required this.details,
  });

  /// For compatibility - returns position
  LatLng get location => position;

  /// Factory constructor from BatterySwapStation entity
  factory StationMarker.fromBatterySwap(BatterySwapStation station) {
    return StationMarker(
      id: station.id,
      name: station.name,
      stationType: 'battery_swap',
      position: LatLng(station.latitude, station.longitude),
      brand: station.brand,
      availabilityPercent: station.availabilityPercent,
      rating: station.averageRating,
      isOperational: station.isOperational,
      details: {
        'address': station.address,
        'batteries_available': station.batteriesAvailable,
        'total_capacity': station.totalCapacity,
        'amenities': station.amenities,
        'operating_hours': station.operatingHours,
        'phone_number': station.phoneNumber,
        'price_per_swap': station.pricePerSwap,
        'currency': station.currency,
      },
    );
  }

  /// Factory constructor from EVChargingStation entity
  factory StationMarker.fromEVCharging(EVChargingStation station) {
    return StationMarker(
      id: station.id,
      name: station.name,
      stationType: 'ev_charging',
      position: LatLng(station.latitude, station.longitude),
      network: station.network,
      availabilityPercent: station.availabilityPercent,
      rating: station.averageRating,
      isOperational: station.isOperational,
      details: {
        'address': station.address,
        'available_ports': station.availablePorts,
        'total_ports': station.totalPorts,
        'connector_types': station.connectorTypes.map((c) => c.displayName).toList(),
        'max_power_kw': station.maxPowerKw,
        'is_24_hours': station.is24Hours,
        'phone_number': station.phoneNumber,
      },
    );
  }

  /// Display name - prefers brand/network over station name
  String get displayName => brand ?? network ?? name;

  /// Human-readable availability text
  String get availabilityText {
    if (availabilityPercent == null) return 'Unknown';
    if (availabilityPercent! >= 75) return 'High availability';
    if (availabilityPercent! >= 50) return 'Medium availability';
    if (availabilityPercent! >= 25) return 'Low availability';
    return 'Very low availability';
  }

  /// Color based on availability percentage
  Color get availabilityColor {
    if (!isOperational) return Colors.grey;
    if (availabilityPercent == null) return Colors.grey;
    if (availabilityPercent! >= 75) return Colors.green;
    if (availabilityPercent! >= 50) return Colors.orange;
    return Colors.red;
  }

  /// Whether this is a battery swap station
  bool get isBatterySwap => stationType == 'battery_swap';

  /// Whether this is an EV charging station
  bool get isEVCharging => stationType == 'ev_charging';

  /// Icon data based on station type
  IconData get iconData =>
      isBatterySwap ? Icons.battery_charging_full : Icons.ev_station;
}
