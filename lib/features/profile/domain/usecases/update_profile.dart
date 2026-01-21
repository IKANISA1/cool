import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating an existing user profile
class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  /// Execute the update profile use case
  Future<Either<Failure, Profile>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      role: params.role,
      countryCode: params.countryCode,
      languages: params.languages,
      vehicleCategory: params.vehicleCategory,
      avatarUrl: params.avatarUrl,
      phoneNumber: params.phoneNumber,
    );
  }
}

/// Parameters for updating a profile
class UpdateProfileParams {
  final String? name;
  final UserRole? role;
  final String? countryCode;
  final List<String>? languages;
  final VehicleCategory? vehicleCategory;
  final String? avatarUrl;
  final String? phoneNumber;

  const UpdateProfileParams({
    this.name,
    this.role,
    this.countryCode,
    this.languages,
    this.vehicleCategory,
    this.avatarUrl,
    this.phoneNumber,
  });

  /// Check if any field is set for update
  bool get hasChanges =>
      name != null ||
      role != null ||
      countryCode != null ||
      languages != null ||
      vehicleCategory != null ||
      avatarUrl != null ||
      phoneNumber != null;
}
