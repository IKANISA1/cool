import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/scheduled_trip.dart';
import '../repositories/scheduling_repository.dart';

/// Use case for fetching scheduled trips
class GetScheduledTrips {
  final SchedulingRepository repository;

  GetScheduledTrips(this.repository);

  /// Get current user's trips
  Future<Either<Failure, List<ScheduledTrip>>> getMyTrips() {
    return repository.getMyTrips();
  }

  /// Get upcoming public trips
  Future<Either<Failure, List<ScheduledTrip>>> getUpcoming({
    TripType? tripType,
    int limit = 20,
  }) {
    return repository.getUpcomingTrips(tripType: tripType, limit: limit);
  }

  /// Search trips with filters
  Future<Either<Failure, List<ScheduledTrip>>> search(SearchTripsParams params) {
    return repository.searchTrips(params);
  }

  /// Watch for nearby trip updates
  Stream<Either<Failure, List<ScheduledTrip>>> watchNearby(
    SearchTripsParams params,
  ) {
    return repository.watchNearbyTrips(params);
  }
}
