import 'package:equatable/equatable.dart';

/// Type of scheduled trip
enum TripType {
  /// Driver offering a ride
  offer,
  
  /// Passenger requesting a ride
  request,
}

/// Entity representing a scheduled trip
///
/// Scheduled trips are future ride offers or requests that users
/// can create in advance. Other users can browse and respond to them.
class ScheduledTrip extends Equatable {
  /// Unique identifier
  final String id;

  /// User who created the trip
  final String userId;

  /// Type of trip (offer or request)
  final TripType tripType;

  /// When the trip is scheduled for
  final DateTime whenDateTime;

  /// Human-readable departure location
  final String fromText;

  /// Human-readable destination
  final String toText;

  /// Departure coordinates (lat, lng)
  final (double, double)? fromGeo;

  /// Destination coordinates (lat, lng)
  final (double, double)? toGeo;

  /// Number of available/needed seats
  final int seatsQty;

  /// Preferred vehicle category (e.g., 'car', 'bike', 'bus')
  final String? vehiclePref;

  /// Additional notes
  final String? notes;

  /// Whether the trip is still active
  final bool isActive;

  /// When the trip was created
  final DateTime createdAt;

  /// When the trip was last updated
  final DateTime updatedAt;

  /// User info (populated from join)
  final TripUser? user;

  const ScheduledTrip({
    required this.id,
    required this.userId,
    required this.tripType,
    required this.whenDateTime,
    required this.fromText,
    required this.toText,
    this.fromGeo,
    this.toGeo,
    this.seatsQty = 1,
    this.vehiclePref,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  /// Whether this is a ride offer
  bool get isOffer => tripType == TripType.offer;

  /// Whether this is a ride request
  bool get isRequest => tripType == TripType.request;

  /// Whether the trip is in the past
  bool get isPast => whenDateTime.isBefore(DateTime.now());

  /// Whether the trip is upcoming
  bool get isUpcoming => !isPast && isActive;

  /// Copy with modifications
  ScheduledTrip copyWith({
    String? id,
    String? userId,
    TripType? tripType,
    DateTime? whenDateTime,
    String? fromText,
    String? toText,
    (double, double)? fromGeo,
    (double, double)? toGeo,
    int? seatsQty,
    String? vehiclePref,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    TripUser? user,
  }) {
    return ScheduledTrip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripType: tripType ?? this.tripType,
      whenDateTime: whenDateTime ?? this.whenDateTime,
      fromText: fromText ?? this.fromText,
      toText: toText ?? this.toText,
      fromGeo: fromGeo ?? this.fromGeo,
      toGeo: toGeo ?? this.toGeo,
      seatsQty: seatsQty ?? this.seatsQty,
      vehiclePref: vehiclePref ?? this.vehiclePref,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tripType,
        whenDateTime,
        fromText,
        toText,
        fromGeo,
        toGeo,
        seatsQty,
        vehiclePref,
        notes,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// User info for trip display
class TripUser extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? rating;

  const TripUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, name, avatarUrl, rating];
}
