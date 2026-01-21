import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/discovery_repository.dart';

/// Use case for updating the user's current location
///
/// This updates the user's location in the presence table
/// for accurate distance calculations in discovery.
class UpdateUserLocation {
  final DiscoveryRepository repository;

  UpdateUserLocation(this.repository);

  /// Update location with optional accuracy and movement data
  Future<Either<Failure, void>> call({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  }) async {
    return repository.updateLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      heading: heading,
      speed: speed,
    );
  }
}
