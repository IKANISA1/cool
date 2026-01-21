import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/features/discovery/domain/entities/nearby_user.dart';
import 'package:ridelink/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:ridelink/features/discovery/domain/usecases/get_nearby_users.dart';
import 'package:ridelink/features/discovery/domain/usecases/toggle_online_status.dart';
import 'package:ridelink/features/discovery/domain/usecases/update_user_location.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_state.dart';

// Mock classes
class MockGetNearbyUsers extends Mock implements GetNearbyUsers {}
class MockToggleOnlineStatus extends Mock implements ToggleOnlineStatus {}
class MockUpdateUserLocation extends Mock implements UpdateUserLocation {}

// Fake classes for registerFallbackValue
class FakeNearbyUsersParams extends Fake implements NearbyUsersParams {}

void main() {
  late DiscoveryBloc bloc;
  late MockGetNearbyUsers mockGetNearbyUsers;
  late MockToggleOnlineStatus mockToggleOnlineStatus;
  late MockUpdateUserLocation mockUpdateUserLocation;

  setUpAll(() {
    registerFallbackValue(FakeNearbyUsersParams());
  });

  setUp(() {
    mockGetNearbyUsers = MockGetNearbyUsers();
    mockToggleOnlineStatus = MockToggleOnlineStatus();
    mockUpdateUserLocation = MockUpdateUserLocation();

    bloc = DiscoveryBloc(
      getNearbyUsers: mockGetNearbyUsers,
      toggleOnlineStatus: mockToggleOnlineStatus,
      updateUserLocation: mockUpdateUserLocation,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const testUsers = [
    NearbyUser(
      id: 'user-1',
      name: 'Jean Driver',
      phone: '+250788000001',
      role: 'driver',
      rating: 4.8,
      verified: true,
      distanceKm: 0.5,
      isOnline: true,
      vehicleCategory: 'moto',
    ),
    NearbyUser(
      id: 'user-2',
      name: 'Marie Passenger',
      phone: '+250788000002',
      role: 'passenger',
      rating: 4.5,
      verified: false,
      distanceKm: 1.2,
      isOnline: true,
    ),
  ];

  const testResult = NearbyUsersResult(
    users: testUsers,
    hasMore: false,
    totalCount: 2,
  );

  group('DiscoveryBloc', () {
    test('initial state is DiscoveryInitial', () {
      expect(bloc.state, const DiscoveryInitial());
    });

    group('LoadNearbyUsers', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryError] when location is not set',
        build: () => bloc,
        act: (b) => b.add(const LoadNearbyUsers()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', contains('Location')),
        ],
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryLoaded] when successful with location',
        build: () {
          when(() => mockGetNearbyUsers(any()))
              .thenAnswer((_) async => const Right(testResult));
          return bloc;
        },
        seed: () => const DiscoveryLoaded(
          latitude: -1.9403,
          longitude: 30.0619,
        ),
        act: (b) => b.add(const LoadNearbyUsers(role: 'driver')),
        expect: () => [
          isA<DiscoveryLoading>()
              .having((s) => s.roleFilter, 'roleFilter', 'driver'),
          isA<DiscoveryLoaded>()
              .having((s) => s.users.length, 'users.length', 2)
              .having((s) => s.roleFilter, 'roleFilter', 'driver'),
        ],
        verify: (_) {
          verify(() => mockGetNearbyUsers(any())).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'emits [DiscoveryLoading, DiscoveryError] when fetch fails',
        build: () {
          when(() => mockGetNearbyUsers(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Network error')));
          return bloc;
        },
        seed: () => const DiscoveryLoaded(
          latitude: -1.9403,
          longitude: 30.0619,
        ),
        act: (b) => b.add(const LoadNearbyUsers()),
        expect: () => [
          isA<DiscoveryLoading>(),
          isA<DiscoveryError>()
              .having((s) => s.message, 'message', 'Network error'),
        ],
      );
    });

    group('ToggleOnlineStatusEvent', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'updates isOnline when toggle succeeds',
        build: () {
          when(() => mockToggleOnlineStatus(true))
              .thenAnswer((_) async => const Right(true));
          return bloc;
        },
        seed: () => const DiscoveryLoaded(isOnline: false),
        act: (b) => b.add(const ToggleOnlineStatusEvent(true)),
        expect: () => [
          isA<DiscoveryLoaded>().having((s) => s.isOnline, 'isOnline', true),
        ],
        verify: (_) {
          verify(() => mockToggleOnlineStatus(true)).called(1);
        },
      );

      blocTest<DiscoveryBloc, DiscoveryState>(
        'does not change state when toggle fails',
        build: () {
          when(() => mockToggleOnlineStatus(true)).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Failed')));
          return bloc;
        },
        seed: () => const DiscoveryLoaded(isOnline: false),
        act: (b) => b.add(const ToggleOnlineStatusEvent(true)),
        expect: () => [], // No state change on failure
      );
    });

    group('UpdateLocationEvent', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'updates location in state',
        build: () {
          when(() => mockUpdateUserLocation(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                accuracy: any(named: 'accuracy'),
                heading: any(named: 'heading'),
                speed: any(named: 'speed'),
              )).thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => const DiscoveryLoaded(
          latitude: 0,
          longitude: 0,
        ),
        act: (b) => b.add(const UpdateLocationEvent(
          latitude: -1.9403,
          longitude: 30.0619,
        )),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having((s) => s.latitude, 'latitude', -1.9403)
              .having((s) => s.longitude, 'longitude', 30.0619),
        ],
        verify: (_) {
          verify(() => mockUpdateUserLocation(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                accuracy: any(named: 'accuracy'),
                heading: any(named: 'heading'),
                speed: any(named: 'speed'),
              )).called(1);
        },
      );
    });

    group('NearbyUsersUpdated', () {
      blocTest<DiscoveryBloc, DiscoveryState>(
        'updates users list from realtime stream',
        build: () => bloc,
        seed: () => const DiscoveryLoaded(
          users: [],
          latitude: -1.9403,
          longitude: 30.0619,
        ),
        act: (b) => b.add(const NearbyUsersUpdated(testUsers)),
        expect: () => [
          isA<DiscoveryLoaded>()
              .having((s) => s.users.length, 'users.length', 2),
        ],
      );
    });
  });

  group('NearbyUser Entity', () {
    test('isDriver returns true for driver role', () {
      const user = NearbyUser(
        id: '1',
        name: 'Test',
        phone: '+250788000001',
        role: 'driver',
        rating: 4.5,
        verified: false,
        distanceKm: 1.0,
        isOnline: true,
      );
      expect(user.isDriver, true);
      expect(user.isPassenger, false);
    });

    test('isPassenger returns true for passenger role', () {
      const user = NearbyUser(
        id: '1',
        name: 'Test',
        phone: '+250788000001',
        role: 'passenger',
        rating: 4.5,
        verified: false,
        distanceKm: 1.0,
        isOnline: true,
      );
      expect(user.isDriver, false);
      expect(user.isPassenger, true);
    });

    test('initials are generated correctly', () {
      const user = NearbyUser(
        id: '1',
        name: 'Jean Pierre',
        phone: '+250788000001',
        role: 'both',
        rating: 4.5,
        verified: false,
        distanceKm: 1.0,
        isOnline: true,
      );
      expect(user.initials, 'JP');
    });

    test('single name returns first character', () {
      const user = NearbyUser(
        id: '1',
        name: 'Jean',
        phone: '+250788000001',
        role: 'both',
        rating: 4.5,
        verified: false,
        distanceKm: 1.0,
        isOnline: true,
      );
      expect(user.initials, 'J');
    });
  });

  group('DiscoveryState', () {
    test('DiscoveryLoaded copyWith preserves values', () {
      const state = DiscoveryLoaded(
        users: testUsers,
        isOnline: true,
        latitude: -1.9403,
        longitude: 30.0619,
      );
      final newState = state.copyWith(isOnline: false);
      expect(newState.users, testUsers);
      expect(newState.isOnline, false);
      expect(newState.latitude, -1.9403);
    });
  });
}
