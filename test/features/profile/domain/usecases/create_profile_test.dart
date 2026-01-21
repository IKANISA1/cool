import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/features/profile/domain/entities/profile.dart';
import 'package:ridelink/features/profile/domain/repositories/profile_repository.dart';
import 'package:ridelink/features/profile/domain/usecases/create_profile.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late CreateProfile usecase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(UserRole.passenger);
    registerFallbackValue(VehicleCategory.cab);
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = CreateProfile(mockRepository);
  });

  group('CreateProfile', () {
    final testProfile = Profile(
      id: 'test-profile-id',
      userId: 'test-user-id',
      name: 'John Doe',
      role: UserRole.passenger,
      countryCode: 'RW',
      languages: ['en', 'rw'],
      createdAt: DateTime(2026, 1, 17),
      updatedAt: DateTime(2026, 1, 17),
    );

    final testParams = CreateProfileParams(
      name: 'John Doe',
      role: UserRole.passenger,
      countryCode: 'RW',
      languages: ['en', 'rw'],
    );

    test('should return Profile when creation is successful', () async {
      // Arrange
      when(() => mockRepository.createProfile(
            name: any(named: 'name'),
            role: any(named: 'role'),
            countryCode: any(named: 'countryCode'),
            languages: any(named: 'languages'),
            vehicleCategory: any(named: 'vehicleCategory'),
            avatarUrl: any(named: 'avatarUrl'),
          )).thenAnswer((_) async => Right(testProfile));

      // Act
      final result = await usecase(testParams);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected success'),
        (profile) {
          expect(profile.name, testProfile.name);
          expect(profile.role, testProfile.role);
        },
      );
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      when(() => mockRepository.createProfile(
            name: any(named: 'name'),
            role: any(named: 'role'),
            countryCode: any(named: 'countryCode'),
            languages: any(named: 'languages'),
            vehicleCategory: any(named: 'vehicleCategory'),
            avatarUrl: any(named: 'avatarUrl'),
          )).thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

      // Act
      final result = await usecase(testParams);

      // Assert
      expect(result.isLeft(), true);
    });

    test('should pass vehicleCategory for drivers', () async {
      // Arrange
      when(() => mockRepository.createProfile(
            name: any(named: 'name'),
            role: any(named: 'role'),
            countryCode: any(named: 'countryCode'),
            languages: any(named: 'languages'),
            vehicleCategory: any(named: 'vehicleCategory'),
            avatarUrl: any(named: 'avatarUrl'),
          )).thenAnswer((_) async => Right(testProfile));

      final driverParams = CreateProfileParams(
        name: 'Jane Driver',
        role: UserRole.driver,
        countryCode: 'RW',
        vehicleCategory: VehicleCategory.cab,
      );

      // Act
      await usecase(driverParams);

      // Assert
      verify(() => mockRepository.createProfile(
            name: 'Jane Driver',
            role: UserRole.driver,
            countryCode: 'RW',
            languages: const [],
            vehicleCategory: VehicleCategory.cab,
            avatarUrl: null,
          )).called(1);
    });
  });
}
