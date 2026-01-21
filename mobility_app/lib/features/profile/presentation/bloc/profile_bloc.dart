import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// BLoC for managing profile state
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  static final _log = Logger('ProfileBloc');

  final GetProfile getProfile;
  final CreateProfile createProfile;
  final UpdateProfile updateProfile;
  final ProfileRepository repository;

  ProfileBloc({
    required this.getProfile,
    required this.createProfile,
    required this.updateProfile,
    required this.repository,
  }) : super(const ProfileInitial()) {
    on<LoadProfileRequested>(_onLoadProfile);
    on<LoadProfileByIdRequested>(_onLoadProfileById);
    on<CheckProfileExistsRequested>(_onCheckProfileExists);
    on<CreateProfileRequested>(_onCreateProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UploadAvatarRequested>(_onUploadAvatar);
    on<ClearProfileError>(_onClearError);
  }

  Future<void> _onLoadProfile(
    LoadProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile();

    result.fold(
      (failure) {
        _log.warning('Failed to load profile: ${failure.message}');
        if (failure.code == 'NOT_FOUND') {
          emit(const ProfileNotFound());
        } else {
          emit(ProfileError(message: failure.message, code: failure.code));
        }
      },
      (profile) {
        _log.fine('Profile loaded: ${profile.name}');
        emit(ProfileLoaded(profile));
      },
    );
  }

  Future<void> _onLoadProfileById(
    LoadProfileByIdRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile.byId(event.userId);

    result.fold(
      (failure) {
        _log.warning('Failed to load profile by ID: ${failure.message}');
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (profile) {
        _log.fine('Profile loaded by ID: ${profile.name}');
        emit(ProfileLoaded(profile));
      },
    );
  }

  Future<void> _onCheckProfileExists(
    CheckProfileExistsRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile.exists();

    result.fold(
      (failure) {
        _log.warning('Failed to check profile existence: ${failure.message}');
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (exists) {
        if (exists) {
          // Load the actual profile
          add(const LoadProfileRequested());
        } else {
          emit(const ProfileNotFound());
        }
      },
    );
  }

  Future<void> _onCreateProfile(
    CreateProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await createProfile(
      CreateProfileParams(
        name: event.name,
        role: event.role,
        countryCode: event.countryCode,
        languages: event.languages,
        vehicleCategory: event.vehicleCategory,
        avatarUrl: event.avatarUrl,
        phoneNumber: event.whatsappNumber,
      ),
    );

    result.fold(
      (failure) {
        _log.warning('Failed to create profile: ${failure.message}');
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (profile) {
        _log.info('Profile created: ${profile.name}');
        emit(ProfileCreated(profile));
      },
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await updateProfile(
      UpdateProfileParams(
        name: event.name,
        role: event.role,
        countryCode: event.countryCode,
        languages: event.languages,
        vehicleCategory: event.vehicleCategory,
        avatarUrl: event.avatarUrl,
        phoneNumber: event.whatsappNumber,
      ),
    );

    result.fold(
      (failure) {
        _log.warning('Failed to update profile: ${failure.message}');
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (profile) {
        _log.info('Profile updated: ${profile.name}');
        emit(ProfileUpdated(profile));
      },
    );
  }

  Future<void> _onUploadAvatar(
    UploadAvatarRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const AvatarUploading());

    final result = await repository.uploadAvatar(event.filePath);

    result.fold(
      (failure) {
        _log.warning('Failed to upload avatar: ${failure.message}');
        emit(ProfileError(message: failure.message, code: failure.code));
      },
      (url) {
        _log.info('Avatar uploaded: $url');
        emit(AvatarUploaded(url));
      },
    );
  }

  void _onClearError(
    ClearProfileError event,
    Emitter<ProfileState> emit,
  ) {
    emit(const ProfileInitial());
  }
}
