import 'package:equatable/equatable.dart';

/// Represents a connector type at an EV charging station
class ConnectorType extends Equatable {
  /// Connector type (e.g., 'CCS', 'CHAdeMO', 'Type2')
  final String type;

  /// Total number of this connector type
  final int count;

  /// Number of available connectors
  final int? available;

  /// Maximum charge rate in kW
  final double? maxChargeRateKw;

  const ConnectorType({
    required this.type,
    required this.count,
    this.available,
    this.maxChargeRateKw,
  });

  /// Get human-readable connector name
  String get displayName {
    switch (type.toUpperCase()) {
      case 'CCS':
      case 'EV_CONNECTOR_TYPE_CCS_COMBO_1':
      case 'EV_CONNECTOR_TYPE_CCS_COMBO_2':
        return 'CCS';
      case 'CHADEMO':
      case 'EV_CONNECTOR_TYPE_CHADEMO':
        return 'CHAdeMO';
      case 'TYPE2':
      case 'J1772':
      case 'EV_CONNECTOR_TYPE_J1772':
        return 'Type 2';
      case 'TESLA':
      case 'EV_CONNECTOR_TYPE_TESLA':
        return 'Tesla';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [type, count, available, maxChargeRateKw];

  factory ConnectorType.fromJson(Map<String, dynamic> json) {
    return ConnectorType(
      type: json['type'] as String? ?? 'unknown',
      count: json['count'] as int? ?? 0,
      available: json['available'] as int?,
      maxChargeRateKw: (json['max_charge_rate_kw'] as num?)?.toDouble(),
    );
  }
}

/// Domain entity representing an EV charging station
class EVChargingStation extends Equatable {
  /// Unique identifier
  final String id;

  /// Station name
  final String name;

  /// Station latitude
  final double latitude;

  /// Station longitude
  final double longitude;

  /// Full address
  final String? address;

  /// City name
  final String? city;

  /// Country code
  final String? country;

  /// Network/operator
  final String? network;

  /// Distance from user in kilometers
  final double? distanceKm;

  /// Number of ports currently available
  final int? availablePorts;

  /// Total number of charging ports
  final int? totalPorts;

  /// Supported connector types with details
  final List<ConnectorType> connectorTypes;

  /// Maximum power output in kW
  final double? maxPowerKw;

  /// Average user rating (0-5)
  final double averageRating;

  /// Total number of ratings
  final int totalRatings;

  /// Whether the station is currently operational
  final bool isOperational;

  /// Operating hours as map
  final Map<String, String>? operatingHours;

  /// Whether station is open 24 hours
  final bool is24Hours;

  /// Phone number for contact
  final String? phoneNumber;

  /// Website URL
  final String? website;

  /// Pricing information
  final Map<String, dynamic>? pricingInfo;

  /// Whether charging is free
  final bool isFree;

  /// Access type (public, private, semi_private)
  final String? accessType;

  /// Whether membership is required
  final bool requiresMembership;

  /// List of amenities
  final List<String>? amenities;

  /// List of payment methods
  final List<String>? paymentMethods;

  /// Last updated timestamp
  final DateTime? updatedAt;

  const EVChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.network,
    this.distanceKm,
    this.availablePorts,
    this.totalPorts,
    this.connectorTypes = const [],
    this.maxPowerKw,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.isOperational = true,
    this.operatingHours,
    this.is24Hours = false,
    this.phoneNumber,
    this.website,
    this.pricingInfo,
    this.isFree = false,
    this.accessType,
    this.requiresMembership = false,
    this.amenities,
    this.paymentMethods,
    this.updatedAt,
  });

  /// Get formatted distance
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toInt()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Availability percentage (0-100)
  double? get availabilityPercent {
    if (availablePorts == null || totalPorts == null || totalPorts == 0) {
      return null;
    }
    return (availablePorts! / totalPorts!) * 100;
  }

  /// Whether ports are available for charging
  bool get hasPortsAvailable =>
      availablePorts != null && availablePorts! > 0;

  /// Whether this is a fast charger (50kW+)
  bool get isFastCharger => maxPowerKw != null && maxPowerKw! >= 50;

  /// Whether this is an ultra-fast charger (150kW+)
  bool get isUltraFastCharger => maxPowerKw != null && maxPowerKw! >= 150;

  /// Charger speed category
  String get chargerSpeedCategory {
    if (maxPowerKw == null) return 'Unknown';
    if (maxPowerKw! >= 150) return 'Ultra-Fast';
    if (maxPowerKw! >= 50) return 'Fast';
    if (maxPowerKw! >= 22) return 'Medium';
    return 'Slow';
  }

  /// Availability text
  String get availabilityText {
    if (availablePorts == null || totalPorts == null) return '';
    return '$availablePorts / $totalPorts available';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        address,
        city,
        country,
        network,
        distanceKm,
        availablePorts,
        totalPorts,
        connectorTypes,
        maxPowerKw,
        averageRating,
        totalRatings,
        isOperational,
        operatingHours,
        is24Hours,
        phoneNumber,
        website,
        pricingInfo,
        isFree,
        accessType,
        requiresMembership,
        amenities,
        paymentMethods,
        updatedAt,
      ];

  EVChargingStation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    String? network,
    double? distanceKm,
    int? availablePorts,
    int? totalPorts,
    List<ConnectorType>? connectorTypes,
    double? maxPowerKw,
    double? averageRating,
    int? totalRatings,
    bool? isOperational,
    Map<String, String>? operatingHours,
    bool? is24Hours,
    String? phoneNumber,
    String? website,
    Map<String, dynamic>? pricingInfo,
    bool? isFree,
    String? accessType,
    bool? requiresMembership,
    List<String>? amenities,
    List<String>? paymentMethods,
    DateTime? updatedAt,
  }) {
    return EVChargingStation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      network: network ?? this.network,
      distanceKm: distanceKm ?? this.distanceKm,
      availablePorts: availablePorts ?? this.availablePorts,
      totalPorts: totalPorts ?? this.totalPorts,
      connectorTypes: connectorTypes ?? this.connectorTypes,
      maxPowerKw: maxPowerKw ?? this.maxPowerKw,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      isOperational: isOperational ?? this.isOperational,
      operatingHours: operatingHours ?? this.operatingHours,
      is24Hours: is24Hours ?? this.is24Hours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      pricingInfo: pricingInfo ?? this.pricingInfo,
      isFree: isFree ?? this.isFree,
      accessType: accessType ?? this.accessType,
      requiresMembership: requiresMembership ?? this.requiresMembership,
      amenities: amenities ?? this.amenities,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
