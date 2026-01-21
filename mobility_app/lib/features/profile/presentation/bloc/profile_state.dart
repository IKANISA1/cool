import 'package:equatable/equatable.dart';

import '../../domain/entities/profile.dart';

/// Profile BLoC states
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading profile data
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile loaded successfully
class ProfileLoaded extends ProfileState {
  final Profile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile does not exist (needs setup)
class ProfileNotFound extends ProfileState {
  const ProfileNotFound();
}

/// Profile created successfully
class ProfileCreated extends ProfileState {
  final Profile profile;

  const ProfileCreated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Profile updated successfully
class ProfileUpdated extends ProfileState {
  final Profile profile;

  const ProfileUpdated(this.profile);

  @override
  List<Object?> get props => [profile];
}

/// Avatar uploaded successfully
class AvatarUploaded extends ProfileState {
  final String avatarUrl;

  const AvatarUploaded(this.avatarUrl);

  @override
  List<Object?> get props => [avatarUrl];
}

/// Uploading avatar in progress
class AvatarUploading extends ProfileState {
  const AvatarUploading();
}

/// Profile error
class ProfileError extends ProfileState {
  final String message;
  final String? code;

  const ProfileError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}
