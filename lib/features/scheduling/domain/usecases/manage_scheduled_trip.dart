import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/scheduled_trip.dart';
import '../repositories/scheduling_repository.dart';

/// Use case for updating or deleting a scheduled trip
class ManageScheduledTrip {
  final SchedulingRepository repository;

  ManageScheduledTrip(this.repository);

  /// Update an existing trip
  Future<Either<Failure, ScheduledTrip>> update(
    String tripId,
    ScheduledTripParams params,
  ) {
    return repository.updateTrip(tripId, params);
  }

  /// Delete/cancel a trip
  Future<Either<Failure, void>> delete(String tripId) {
    return repository.deleteTrip(tripId);
  }

  /// Watch a specific trip for updates
  Stream<Either<Failure, ScheduledTrip>> watch(String tripId) {
    return repository.watchTrip(tripId);
  }
}
