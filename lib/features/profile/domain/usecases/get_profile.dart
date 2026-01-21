import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting the current user's profile
class GetProfile {
  final ProfileRepository repository;

  GetProfile(this.repository);

  /// Execute the get profile use case
  Future<Either<Failure, Profile>> call() {
    return repository.getProfile();
  }

  /// Get profile by user ID
  Future<Either<Failure, Profile>> byId(String userId) {
    return repository.getProfileById(userId);
  }

  /// Check if profile exists
  Future<Either<Failure, bool>> exists() {
    return repository.hasProfile();
  }
}
