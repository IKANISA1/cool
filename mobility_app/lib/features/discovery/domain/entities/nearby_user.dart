import 'package:equatable/equatable.dart';

/// Domain entity representing a nearby user (driver or passenger)
///
/// Contains all information needed to display a user in the discovery list
/// and to initiate a ride request.
class NearbyUser extends Equatable {
  /// Unique identifier
  final String id;

  /// User's display name
  final String name;

  /// User's phone number (for WhatsApp)
  final String phone;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// User's role: 'driver', 'passenger', or 'both'
  final String role;

  /// User's average rating (0-5)
  final double rating;

  /// Whether user is verified
  final bool verified;

  /// Distance from current user in kilometers
  final double distanceKm;

  /// Whether user is currently online
  final bool isOnline;

  /// Last seen timestamp
  final DateTime? lastSeenAt;

  /// Vehicle category (for drivers): 'moto', 'cab', 'liffan', 'truck', 'rent', 'other'
  final String? vehicleCategory;

  /// Vehicle passenger capacity
  final int? vehicleCapacity;

  /// Vehicle plate number
  final String? vehiclePlate;

  /// Vehicle make/model
  final String? vehicleDescription;

  /// User's country code (ISO 3166-1 alpha-3)
  final String? country;

  /// Languages spoken
  final List<String>? languages;

  /// User's current latitude
  final double? latitude;

  /// User's current longitude
  final double? longitude;

  const NearbyUser({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.rating,
    required this.verified,
    required this.distanceKm,
    required this.isOnline,
    this.lastSeenAt,
    this.vehicleCategory,
    this.vehicleCapacity,
    this.vehiclePlate,
    this.vehicleDescription,
    this.country,
    this.languages,
    this.latitude,
    this.longitude,
  });

  /// Whether this user is a driver (has vehicle info)
  bool get isDriver => 
      role == 'driver' || role == 'both' || vehicleCategory != null;

  /// Whether this user can be a passenger
  bool get isPassenger => role == 'passenger' || role == 'both';

  /// Get initials from name for avatar fallback
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return name.isNotEmpty ? name[0] : '?';
  }

  /// Copy with updated fields
  NearbyUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatarUrl,
    String? role,
    double? rating,
    bool? verified,
    double? distanceKm,
    bool? isOnline,
    DateTime? lastSeenAt,
    String? vehicleCategory,
    int? vehicleCapacity,
    String? vehiclePlate,
    String? vehicleDescription,
    String? country,
    List<String>? languages,
    double? latitude,
    double? longitude,
  }) {
    return NearbyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      distanceKm: distanceKm ?? this.distanceKm,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleDescription: vehicleDescription ?? this.vehicleDescription,
      country: country ?? this.country,
      languages: languages ?? this.languages,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        avatarUrl,
        role,
        rating,
        verified,
        distanceKm,
        isOnline,
        lastSeenAt,
        vehicleCategory,
        vehicleCapacity,
        vehiclePlate,
        vehicleDescription,
        country,
        languages,
        latitude,
        longitude,
      ];
}
