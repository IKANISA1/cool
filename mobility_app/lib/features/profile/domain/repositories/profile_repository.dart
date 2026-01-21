import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get the current user's profile
  Future<Either<Failure, Profile>> getProfile();

  /// Get a profile by user ID
  Future<Either<Failure, Profile>> getProfileById(String userId);

  /// Create a new profile
  Future<Either<Failure, Profile>> createProfile({
    required String name,
    required UserRole role,
    required String countryCode,
    List<String> languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  });

  /// Update an existing profile
  Future<Either<Failure, Profile>> updateProfile({
    String? name,
    UserRole? role,
    String? countryCode,
    List<String>? languages,
    VehicleCategory? vehicleCategory,
    String? avatarUrl,
    String? phoneNumber,
  });

  /// Check if profile exists for current user
  Future<Either<Failure, bool>> hasProfile();

  /// Upload avatar image and get URL
  Future<Either<Failure, String>> uploadAvatar(String filePath);
}
