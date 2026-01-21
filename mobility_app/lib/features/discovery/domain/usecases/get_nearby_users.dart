import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/nearby_user.dart';
import '../repositories/discovery_repository.dart';

/// Use case for fetching nearby users
///
/// Fetches users within a specified radius of the given location,
/// with optional filtering by role and vehicle type.
class GetNearbyUsers {
  final DiscoveryRepository repository;

  GetNearbyUsers(this.repository);

  /// Execute the use case
  Future<Either<Failure, NearbyUsersResult>> call(
    NearbyUsersParams params,
  ) async {
    return repository.getNearbyUsers(params);
  }

  /// Get a stream of realtime updates
  Stream<Either<Failure, List<NearbyUser>>> watch(
    NearbyUsersParams params,
  ) {
    return repository.watchNearbyUsers(params);
  }
}
