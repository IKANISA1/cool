import 'package:equatable/equatable.dart';

/// Base class for all station types (Battery Swap, EV Charging, etc.)
abstract class Station extends Equatable {
  /// Unique station identifier
  final String id;

  /// Station name
  final String name;

  /// Full address
  final String address;

  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Distance from user in kilometers (calculated)
  final double? distanceKm;

  /// Average user rating (0-5)
  final double averageRating;

  /// Total number of ratings
  final int ratingCount;

  /// Whether station is currently operational
  final bool isOperational;

  /// Operating hours (e.g., "24/7" or "6:00 AM - 10:00 PM")
  final String? operatingHours;

  /// Contact phone number
  final String? phoneNumber;

  /// Station image URL
  final String? imageUrl;

  /// Last update timestamp
  final DateTime? lastUpdated;

  const Station({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.isOperational = true,
    this.operatingHours,
    this.phoneNumber,
    this.imageUrl,
    this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        distanceKm,
        averageRating,
        ratingCount,
        isOperational,
        operatingHours,
        phoneNumber,
        imageUrl,
        lastUpdated,
      ];
}
