import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/scheduled_trip.dart';
import '../repositories/scheduling_repository.dart';

/// Use case for creating a new scheduled trip
class CreateScheduledTrip {
  final SchedulingRepository repository;

  CreateScheduledTrip(this.repository);

  /// Create a trip offer or request
  Future<Either<Failure, ScheduledTrip>> call(ScheduledTripParams params) {
    return repository.createTrip(params);
  }
}
