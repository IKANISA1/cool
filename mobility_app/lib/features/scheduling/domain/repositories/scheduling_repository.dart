import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/scheduled_trip.dart';

/// Parameters for creating or updating a scheduled trip
class ScheduledTripParams {
  final TripType tripType;
  final DateTime whenDateTime;
  final String fromText;
  final String toText;
  final (double, double)? fromGeo;
  final (double, double)? toGeo;
  final int seatsQty;
  final String? vehiclePref;
  final String? notes;

  const ScheduledTripParams({
    required this.tripType,
    required this.whenDateTime,
    required this.fromText,
    required this.toText,
    this.fromGeo,
    this.toGeo,
    this.seatsQty = 1,
    this.vehiclePref,
    this.notes,
  });
}

/// Parameters for searching scheduled trips
class SearchTripsParams {
  /// Filter by trip type
  final TripType? tripType;

  /// Filter by date range
  final DateTime? fromDate;
  final DateTime? toDate;

  /// Filter by location (within radius of this point)
  final (double, double)? nearLocation;
  final double radiusKm;

  /// Filter by vehicle preference
  final String? vehiclePref;

  /// Pagination
  final int page;
  final int pageSize;

  /// Exclude current user's trips
  final String? excludeUserId;

  const SearchTripsParams({
    this.tripType,
    this.fromDate,
    this.toDate,
    this.nearLocation,
    this.radiusKm = 20.0,
    this.vehiclePref,
    this.page = 1,
    this.pageSize = 20,
    this.excludeUserId,
  });
}

/// Abstract repository interface for scheduling operations
abstract class SchedulingRepository {
  /// Create a new scheduled trip
  Future<Either<Failure, ScheduledTrip>> createTrip(ScheduledTripParams params);

  /// Update an existing trip
  Future<Either<Failure, ScheduledTrip>> updateTrip(
    String tripId,
    ScheduledTripParams params,
  );

  /// Delete/cancel a trip
  Future<Either<Failure, void>> deleteTrip(String tripId);

  /// Get a single trip by ID
  Future<Either<Failure, ScheduledTrip>> getTrip(String tripId);

  /// Get all trips for the current user
  Future<Either<Failure, List<ScheduledTrip>>> getMyTrips();

  /// Search trips with filters
  Future<Either<Failure, List<ScheduledTrip>>> searchTrips(
    SearchTripsParams params,
  );

  /// Get upcoming trips (public)
  Future<Either<Failure, List<ScheduledTrip>>> getUpcomingTrips({
    TripType? tripType,
    int limit = 20,
  });

  /// Subscribe to realtime trip updates
  Stream<Either<Failure, ScheduledTrip>> watchTrip(String tripId);

  /// Subscribe to new trips in area
  Stream<Either<Failure, List<ScheduledTrip>>> watchNearbyTrips(
    SearchTripsParams params,
  );
}
