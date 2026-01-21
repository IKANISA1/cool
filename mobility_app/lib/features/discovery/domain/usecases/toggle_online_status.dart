import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/discovery_repository.dart';

/// Use case for toggling the user's online/offline status
///
/// When online, the user is visible to other users in discovery.
/// When offline, they won't appear in nearby searches.
class ToggleOnlineStatus {
  final DiscoveryRepository repository;

  ToggleOnlineStatus(this.repository);

  /// Toggle online status
  /// 
  /// Returns the new status after toggling
  Future<Either<Failure, bool>> call(bool isOnline) async {
    return repository.toggleOnlineStatus(isOnline);
  }
}
