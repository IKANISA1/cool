import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/features/profile/domain/entities/profile.dart';
import 'package:ridelink/features/profile/domain/repositories/profile_repository.dart';
import 'package:ridelink/features/profile/domain/usecases/create_profile.dart';
import 'package:ridelink/features/profile/domain/usecases/get_profile.dart';
import 'package:ridelink/features/profile/domain/usecases/update_profile.dart';
import 'package:ridelink/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ridelink/features/profile/presentation/bloc/profile_event.dart';
import 'package:ridelink/features/profile/presentation/bloc/profile_state.dart';

// Mock classes
class MockGetProfile extends Mock implements GetProfile {}
class MockCreateProfile extends Mock implements CreateProfile {}
class MockUpdateProfile extends Mock implements UpdateProfile {}
class MockProfileRepository extends Mock implements ProfileRepository {}

// Fake classes for registerFallbackValue
class FakeCreateProfileParams extends Fake implements CreateProfileParams {}
class FakeUpdateProfileParams extends Fake implements UpdateProfileParams {}

void main() {
  late ProfileBloc profileBloc;
  late MockGetProfile mockGetProfile;
  late MockCreateProfile mockCreateProfile;
  late MockUpdateProfile mockUpdateProfile;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCreateProfileParams());
    registerFallbackValue(FakeUpdateProfileParams());
  });

  setUp(() {
    mockGetProfile = MockGetProfile();
    mockCreateProfile = MockCreateProfile();
    mockUpdateProfile = MockUpdateProfile();
    mockRepository = MockProfileRepository();

    profileBloc = ProfileBloc(
      getProfile: mockGetProfile,
      createProfile: mockCreateProfile,
      updateProfile: mockUpdateProfile,
      repository: mockRepository,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  final testProfile = Profile(
    id: 'profile-id',
    userId: 'user-id',
    name: 'Jean Test',
    role: UserRole.driver,
    countryCode: 'RWA',
    languages: const ['en', 'rw'],
    isVerified: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('ProfileBloc', () {
    test('initial state is ProfileInitial', () {
      expect(profileBloc.state, const ProfileInitial());
    });

    group('LoadProfileRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when successful',
        build: () {
          when(() => mockGetProfile())
              .thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const LoadProfileRequested()),
        expect: () => [
          const ProfileLoading(),
          ProfileLoaded(testProfile),
        ],
        verify: (_) {
          verify(() => mockGetProfile()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileNotFound] when profile does not exist',
        build: () {
          when(() => mockGetProfile()).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'not found', code: 'NOT_FOUND')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const LoadProfileRequested()),
        expect: () => [
          const ProfileLoading(),
          const ProfileNotFound(),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when loading fails',
        build: () {
          when(() => mockGetProfile()).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Server error')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const LoadProfileRequested()),
        expect: () => [
          const ProfileLoading(),
          isA<ProfileError>().having((e) => e.message, 'message', 'Server error'),
        ],
      );
    });

    group('CreateProfileRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileCreated] when successful',
        build: () {
          when(() => mockCreateProfile(any()))
              .thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const CreateProfileRequested(
          name: 'Jean Test',
          role: 'driver',
          countryCode: 'RWA',
          languages: ['en', 'rw'],
        )),
        expect: () => [
          const ProfileLoading(),
          ProfileCreated(testProfile),
        ],
        verify: (_) {
          verify(() => mockCreateProfile(any())).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when creation fails',
        build: () {
          when(() => mockCreateProfile(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Duplicate key')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const CreateProfileRequested(
          name: 'Test',
          role: 'passenger',
          countryCode: 'RWA',
          languages: ['en'],
        )),
        expect: () => [
          const ProfileLoading(),
          isA<ProfileError>().having((e) => e.message, 'message', 'Duplicate key'),
        ],
      );
    });

    group('UpdateProfileRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileUpdated] when successful',
        build: () {
          when(() => mockUpdateProfile(any()))
              .thenAnswer((_) async => Right(testProfile));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const UpdateProfileRequested(
          name: 'Updated Name',
        )),
        expect: () => [
          const ProfileLoading(),
          ProfileUpdated(testProfile),
        ],
        verify: (_) {
          verify(() => mockUpdateProfile(any())).called(1);
        },
      );
    });

    group('UploadAvatarRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [AvatarUploading, AvatarUploaded] when successful',
        build: () {
          when(() => mockRepository.uploadAvatar(any()))
              .thenAnswer((_) async => const Right('https://example.com/avatar.jpg'));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const UploadAvatarRequested(filePath: '/path/to/image.jpg')),
        expect: () => [
          const AvatarUploading(),
          const AvatarUploaded('https://example.com/avatar.jpg'),
        ],
        verify: (_) {
          verify(() => mockRepository.uploadAvatar('/path/to/image.jpg')).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [AvatarUploading, ProfileError] when upload fails',
        build: () {
          when(() => mockRepository.uploadAvatar(any()))
              .thenAnswer((_) async => const Left(ServerFailure(message: 'Upload failed')));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const UploadAvatarRequested(filePath: '/path/to/image.jpg')),
        expect: () => [
          const AvatarUploading(),
          isA<ProfileError>().having((e) => e.message, 'message', 'Upload failed'),
        ],
      );
    });

    group('ClearProfileError', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileInitial] to clear error state',
        build: () => profileBloc,
        seed: () => const ProfileError(message: 'Some error'),
        act: (bloc) => bloc.add(const ClearProfileError()),
        expect: () => [const ProfileInitial()],
      );
    });
  });

  group('Profile Entity', () {
    test('canDrive returns true for driver role', () {
      expect(testProfile.canDrive, true);
    });

    test('isComplete returns true for complete profile', () {
      final completeProfile = testProfile.copyWith(
        vehicleCategory: VehicleCategory.moto,
      );
      expect(completeProfile.isComplete, true);
    });

    test('needsVehicle returns true for driver without vehicle', () {
      expect(testProfile.needsVehicle, true);
    });
  });
}
