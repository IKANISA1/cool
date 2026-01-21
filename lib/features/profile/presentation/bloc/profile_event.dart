import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

/// Profile BLoC events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load current user's profile
class LoadProfileRequested extends ProfileEvent {
  const LoadProfileRequested();
}

/// Load profile by user ID
class LoadProfileByIdRequested extends ProfileEvent {
  final String userId;

  const LoadProfileByIdRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Check if profile exists
class CheckProfileExistsRequested extends ProfileEvent {
  const CheckProfileExistsRequested();
}

/// Create a new profile
class CreateProfileRequested extends ProfileEvent {
  final String name;
  final UserRole role;
  final String countryCode;
  final List<String> languages;
  final VehicleCategory? vehicleCategory;
  final String? avatarUrl;
  final String? whatsappNumber;

  const CreateProfileRequested({
    required this.name,
    required this.role,
    required this.countryCode,
    this.languages = const [],
    this.vehicleCategory,
    this.avatarUrl,
    this.whatsappNumber,
  });

  @override
  List<Object?> get props => [
        name,
        role,
        countryCode,
        languages,
        vehicleCategory,
        avatarUrl,
        whatsappNumber,
      ];
}

/// Update existing profile
class UpdateProfileRequested extends ProfileEvent {
  final String? name;
  final UserRole? role;
  final String? countryCode;
  final List<String>? languages;
  final VehicleCategory? vehicleCategory;
  final String? avatarUrl;
  final String? whatsappNumber;

  const UpdateProfileRequested({
    this.name,
    this.role,
    this.countryCode,
    this.languages,
    this.vehicleCategory,
    this.avatarUrl,
    this.whatsappNumber,
  });

  @override
  List<Object?> get props => [
        name,
        role,
        countryCode,
        languages,
        vehicleCategory,
        avatarUrl,
        whatsappNumber,
      ];
}

/// Upload avatar image
class UploadAvatarRequested extends ProfileEvent {
  final String filePath;

  const UploadAvatarRequested(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Clear any profile error
class ClearProfileError extends ProfileEvent {
  const ClearProfileError();
}
