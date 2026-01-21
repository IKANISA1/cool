import '../../domain/entities/nearby_user.dart';

/// Data model for nearby user with JSON serialization
///
/// Maps from Supabase `nearby_users` function response to domain entity.
class NearbyUserModel extends NearbyUser {
  const NearbyUserModel({
    required super.id,
    required super.name,
    required super.phone,
    super.avatarUrl,
    required super.role,
    required super.rating,
    required super.verified,
    required super.distanceKm,
    required super.isOnline,
    super.lastSeenAt,
    super.vehicleCategory,
    super.vehicleCapacity,
    super.vehiclePlate,
    super.vehicleDescription,
    super.country,
    super.languages,
    super.latitude,
    super.longitude,
  });

  /// Create from Supabase nearby_users function response
  ///
  /// The function returns:
  /// {
  ///   "user_id": "uuid",
  ///   "distance_km": 1.5,
  ///   "profile": { ... },
  ///   "vehicle": { ... } or null,
  ///   "is_online": true,
  ///   "last_seen_at": "2024-01-01T00:00:00Z"
  /// }
  factory NearbyUserModel.fromSupabaseRow(Map<String, dynamic> row) {
    final profile = row['profile'] as Map<String, dynamic>? ?? {};
    final vehicle = row['vehicle'] as Map<String, dynamic>?;

    return NearbyUserModel(
      id: row['user_id'] as String,
      name: profile['name'] as String? ?? 'Unknown',
      phone: _extractPhone(row, profile),
      avatarUrl: profile['avatar_url'] as String?,
      role: profile['role'] as String? ?? 'passenger',
      rating: _parseDouble(profile['rating']) ?? 0.0,
      verified: profile['verified'] as bool? ?? false,
      distanceKm: _parseDouble(row['distance_km']) ?? 0.0,
      isOnline: row['is_online'] as bool? ?? false,
      lastSeenAt: _parseDateTime(row['last_seen_at']),
      vehicleCategory: vehicle?['category'] as String?,
      vehicleCapacity: vehicle?['capacity'] as int?,
      vehiclePlate: vehicle?['plate'] as String?,
      vehicleDescription: _buildVehicleDescription(vehicle),
      country: profile['country'] as String?,
      languages: _parseLanguages(profile['languages']),
      latitude: _parseDouble(row['last_lat']),
      longitude: _parseDouble(row['last_lng']),
    );
  }

  /// Create from simple profile row (for search results)
  factory NearbyUserModel.fromProfileRow(
    Map<String, dynamic> profile, {
    double distanceKm = 0.0,
  }) {
    return NearbyUserModel(
      id: profile['id'] as String,
      name: profile['name'] as String? ?? 'Unknown',
      phone: profile['phone'] as String? ?? '',
      avatarUrl: profile['avatar_url'] as String?,
      role: profile['role'] as String? ?? 'passenger',
      rating: _parseDouble(profile['rating']) ?? 0.0,
      verified: profile['verified'] as bool? ?? false,
      distanceKm: distanceKm,
      isOnline: false,
      country: profile['country'] as String?,
      languages: _parseLanguages(profile['languages']),
    );
  }

  /// Convert to JSON for storage/caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'rating': rating,
      'verified': verified,
      'distance_km': distanceKm,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'vehicle_category': vehicleCategory,
      'vehicle_capacity': vehicleCapacity,
      'vehicle_plate': vehiclePlate,
      'vehicle_description': vehicleDescription,
      'country': country,
      'languages': languages,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create from JSON (cached data)
  factory NearbyUserModel.fromJson(Map<String, dynamic> json) {
    return NearbyUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      rating: _parseDouble(json['rating']) ?? 0.0,
      verified: json['verified'] as bool? ?? false,
      distanceKm: _parseDouble(json['distance_km']) ?? 0.0,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: _parseDateTime(json['last_seen_at']),
      vehicleCategory: json['vehicle_category'] as String?,
      vehicleCapacity: json['vehicle_capacity'] as int?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleDescription: json['vehicle_description'] as String?,
      country: json['country'] as String?,
      languages: _parseLanguages(json['languages']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  // Helper methods
  static String _extractPhone(
    Map<String, dynamic> row,
    Map<String, dynamic> profile,
  ) {
    // Phone might be in the user table, not profile
    return profile['phone'] as String? ?? 
           row['phone'] as String? ?? '';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static List<String>? _parseLanguages(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.cast<String>();
    return null;
  }

  static String? _buildVehicleDescription(Map<String, dynamic>? vehicle) {
    if (vehicle == null) return null;
    final make = vehicle['make'] as String?;
    final model = vehicle['model'] as String?;
    final year = vehicle['year'];
    final color = vehicle['color'] as String?;

    final parts = <String>[];
    if (color != null) parts.add(color);
    if (year != null) parts.add(year.toString());
    if (make != null) parts.add(make);
    if (model != null) parts.add(model);

    return parts.isNotEmpty ? parts.join(' ') : null;
  }
}
