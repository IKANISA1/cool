import 'package:equatable/equatable.dart';

/// Domain entity representing a battery swap station
///
/// Contains information for displaying swap stations on maps and in lists.
class BatterySwapStation extends Equatable {
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

  /// Country code (ISO 3166-1 alpha-3)
  final String? country;

  /// Brand/operator (e.g., 'Ampersand', 'Spiro')
  final String? brand;

  /// Distance from user in kilometers
  final double? distanceKm;

  /// Number of batteries currently available
  final int? batteriesAvailable;

  /// Total battery capacity at this station
  final int? totalCapacity;

  /// List of amenities (e.g., 'wifi', 'restroom', 'food')
  final List<String>? amenities;

  /// List of payment methods (e.g., 'cash', 'momo', 'card')
  final List<String>? paymentMethods;

  /// Average user rating (0-5)
  final double averageRating;

  /// Total number of ratings
  final int totalRatings;

  /// Whether the station is currently operational
  final bool isOperational;

  /// Operating hours as map (e.g., {'monday': '06:00-22:00'})
  final Map<String, String>? operatingHours;

  /// Whether the station is open 24 hours
  final bool is24Hours;

  /// Phone number for contact
  final String? phoneNumber;

  /// Email address
  final String? email;

  /// Website URL
  final String? website;

  /// Supported battery types
  final List<String>? supportedBatteryTypes;

  /// Price per swap in local currency
  final double? pricePerSwap;

  /// Currency code (e.g., 'RWF', 'USD')
  final String? currency;

  /// Average swap time in minutes
  final int? swapTimeMinutes;

  /// Last updated timestamp
  final DateTime? updatedAt;

  const BatterySwapStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.brand,
    this.distanceKm,
    this.batteriesAvailable,
    this.totalCapacity,
    this.amenities,
    this.paymentMethods,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.isOperational = true,
    this.operatingHours,
    this.is24Hours = false,
    this.phoneNumber,
    this.email,
    this.website,
    this.supportedBatteryTypes,
    this.pricePerSwap,
    this.currency,
    this.swapTimeMinutes,
    this.updatedAt,
  });

  /// Availability percentage (0-100)
  double? get availabilityPercent {
    if (batteriesAvailable == null || totalCapacity == null || totalCapacity == 0) {
      return null;
    }
    return (batteriesAvailable! / totalCapacity!) * 100;
  }

  /// Whether batteries are available for swap
  bool get hasBatteriesAvailable =>
      batteriesAvailable != null && batteriesAvailable! > 0;

  /// Get formatted distance
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toInt()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Get formatted price
  String get formattedPrice {
    if (pricePerSwap == null) return '';
    return '${currency ?? 'RWF'} ${pricePerSwap!.toStringAsFixed(0)}';
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
        brand,
        distanceKm,
        batteriesAvailable,
        totalCapacity,
        amenities,
        paymentMethods,
        averageRating,
        totalRatings,
        isOperational,
        operatingHours,
        is24Hours,
        phoneNumber,
        email,
        website,
        supportedBatteryTypes,
        pricePerSwap,
        currency,
        swapTimeMinutes,
        updatedAt,
      ];

  BatterySwapStation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? country,
    String? brand,
    double? distanceKm,
    int? batteriesAvailable,
    int? totalCapacity,
    List<String>? amenities,
    List<String>? paymentMethods,
    double? averageRating,
    int? totalRatings,
    bool? isOperational,
    Map<String, String>? operatingHours,
    bool? is24Hours,
    String? phoneNumber,
    String? email,
    String? website,
    List<String>? supportedBatteryTypes,
    double? pricePerSwap,
    String? currency,
    int? swapTimeMinutes,
    DateTime? updatedAt,
  }) {
    return BatterySwapStation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      brand: brand ?? this.brand,
      distanceKm: distanceKm ?? this.distanceKm,
      batteriesAvailable: batteriesAvailable ?? this.batteriesAvailable,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      amenities: amenities ?? this.amenities,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      isOperational: isOperational ?? this.isOperational,
      operatingHours: operatingHours ?? this.operatingHours,
      is24Hours: is24Hours ?? this.is24Hours,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      supportedBatteryTypes: supportedBatteryTypes ?? this.supportedBatteryTypes,
      pricePerSwap: pricePerSwap ?? this.pricePerSwap,
      currency: currency ?? this.currency,
      swapTimeMinutes: swapTimeMinutes ?? this.swapTimeMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
