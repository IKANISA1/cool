import '../../domain/entities/scheduled_trip.dart';

/// Data model for ScheduledTrip entity
///
/// Handles serialization/deserialization from Supabase
class ScheduledTripModel extends ScheduledTrip {
  const ScheduledTripModel({
    required super.id,
    required super.userId,
    required super.tripType,
    required super.whenDateTime,
    required super.fromText,
    required super.toText,
    super.fromGeo,
    super.toGeo,
    super.seatsQty,
    super.vehiclePref,
    super.notes,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.user,
  });

  /// Create from Supabase row
  factory ScheduledTripModel.fromSupabaseRow(Map<String, dynamic> row) {
    // Parse trip type
    final tripTypeStr = row['trip_type'] as String? ?? 'request';
    final tripType =
        tripTypeStr == 'offer' ? TripType.offer : TripType.request;

    // Parse geo points if present
    (double, double)? fromGeo;
    (double, double)? toGeo;

    if (row['from_geo'] != null) {
      final fromPoint = row['from_geo'];
      if (fromPoint is Map) {
        final coords = fromPoint['coordinates'] as List?;
        if (coords != null && coords.length >= 2) {
          fromGeo = ((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
        }
      }
    }

    if (row['to_geo'] != null) {
      final toPoint = row['to_geo'];
      if (toPoint is Map) {
        final coords = toPoint['coordinates'] as List?;
        if (coords != null && coords.length >= 2) {
          toGeo = ((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
        }
      }
    }

    // Parse user if joined
    TripUserModel? user;
    if (row['profiles'] != null && row['profiles'] is Map) {
      user = TripUserModel.fromSupabaseRow(
        row['profiles'] as Map<String, dynamic>,
      );
    }

    return ScheduledTripModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tripType: tripType,
      whenDateTime: DateTime.parse(row['when_datetime'] as String),
      fromText: row['from_text'] as String? ?? '',
      toText: row['to_text'] as String? ?? '',
      fromGeo: fromGeo,
      toGeo: toGeo,
      seatsQty: row['seats_qty'] as int? ?? 1,
      vehiclePref: row['vehicle_pref'] as String?,
      notes: row['notes'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      user: user,
    );
  }

  /// Convert to Supabase insert/update map
  Map<String, dynamic> toSupabaseRow() {
    final map = <String, dynamic>{
      'trip_type': tripType == TripType.offer ? 'offer' : 'request',
      'when_datetime': whenDateTime.toIso8601String(),
      'from_text': fromText,
      'to_text': toText,
      'seats_qty': seatsQty,
      'vehicle_pref': vehiclePref,
      'notes': notes,
      'is_active': isActive,
    };

    // Add geo points if present (PostGIS format)
    if (fromGeo != null) {
      map['from_geo'] = 'POINT(${fromGeo!.$2} ${fromGeo!.$1})';
    }
    if (toGeo != null) {
      map['to_geo'] = 'POINT(${toGeo!.$2} ${toGeo!.$1})';
    }

    return map;
  }
}

/// Data model for TripUser
class TripUserModel extends TripUser {
  const TripUserModel({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.rating,
  });

  factory TripUserModel.fromSupabaseRow(Map<String, dynamic> row) {
    return TripUserModel(
      id: row['user_id'] as String? ?? row['id'] as String,
      name: row['name'] as String? ?? 'Unknown',
      avatarUrl: row['avatar_url'] as String?,
      rating: (row['rating'] as num?)?.toDouble(),
    );
  }
}
