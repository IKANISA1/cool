import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for creating a new user profile
class CreateProfile {
  final ProfileRepository repository;

  CreateProfile(this.repository);

  /// Execute the create profile use case
  Future<Either<Failure, Profile>> call(CreateProfileParams params) {
    return repository.createProfile(
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

/// Parameters for creating a profile
class CreateProfileParams {
  final String name;
  final UserRole role;
  final String countryCode;
  final List<String> languages;
  final VehicleCategory? vehicleCategory;
  final String? avatarUrl;
  final String? phoneNumber;

  const CreateProfileParams({
    required this.name,
    required this.role,
    required this.countryCode,
    this.languages = const [],
    this.vehicleCategory,
    this.avatarUrl,
    this.phoneNumber,
  });
}
