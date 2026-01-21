import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/features/scheduling/domain/entities/scheduled_trip.dart';
import 'package:ridelink/features/scheduling/domain/usecases/create_scheduled_trip.dart';
import 'package:ridelink/features/scheduling/domain/usecases/get_scheduled_trips.dart';
import 'package:ridelink/features/scheduling/domain/usecases/manage_scheduled_trip.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_bloc.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_event.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_state.dart';

// Mock classes
class MockCreateScheduledTrip extends Mock implements CreateScheduledTrip {}
class MockGetScheduledTrips extends Mock implements GetScheduledTrips {}
class MockManageScheduledTrip extends Mock implements ManageScheduledTrip {}

void main() {
  late SchedulingBloc bloc;
  late MockCreateScheduledTrip mockCreateScheduledTrip;
  late MockGetScheduledTrips mockGetScheduledTrips;
  late MockManageScheduledTrip mockManageScheduledTrip;

  setUp(() {
    mockCreateScheduledTrip = MockCreateScheduledTrip();
    mockGetScheduledTrips = MockGetScheduledTrips();
    mockManageScheduledTrip = MockManageScheduledTrip();

    bloc = SchedulingBloc(
      createScheduledTrip: mockCreateScheduledTrip,
      getScheduledTrips: mockGetScheduledTrips,
      manageScheduledTrip: mockManageScheduledTrip,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final now = DateTime.now();
  final testTrips = [
    ScheduledTrip(
      id: 'trip-1',
      userId: 'user-1',
      tripType: TripType.offer,
      whenDateTime: now.add(const Duration(hours: 2)),
      fromText: 'Kigali City Centre',
      toText: 'Nyarutarama',
      seatsQty: 3,
      createdAt: now,
      updatedAt: now,
    ),
    ScheduledTrip(
      id: 'trip-2',
      userId: 'user-2',
      tripType: TripType.request,
      whenDateTime: now.add(const Duration(days: 1)),
      fromText: 'Kimironko',
      toText: 'Downtown',
      seatsQty: 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('SchedulingBloc', () {
    test('initial state is SchedulingInitial', () {
      expect(bloc.state, const SchedulingInitial());
    });

    group('LoadMyTrips', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'emits [SchedulingLoading, SchedulingLoaded] when successful',
        build: () {
          when(() => mockGetScheduledTrips.getMyTrips())
              .thenAnswer((_) async => Right(testTrips));
          return bloc;
        },
        act: (b) => b.add(const LoadMyTrips()),
        expect: () => [
          isA<SchedulingLoading>(),
          isA<SchedulingLoaded>()
              .having((s) => s.myTrips.length, 'myTrips.length', 2),
        ],
        verify: (_) {
          verify(() => mockGetScheduledTrips.getMyTrips()).called(1);
        },
      );

      blocTest<SchedulingBloc, SchedulingState>(
        'emits [SchedulingLoading, SchedulingError] when fails',
        build: () {
          when(() => mockGetScheduledTrips.getMyTrips()).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Network error')));
          return bloc;
        },
        act: (b) => b.add(const LoadMyTrips()),
        expect: () => [
          isA<SchedulingLoading>(),
          isA<SchedulingError>()
              .having((s) => s.message, 'message', 'Network error'),
        ],
      );
    });

    group('LoadUpcomingTrips', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'emits [SchedulingLoading, SchedulingLoaded] when successful',
        build: () {
          when(() => mockGetScheduledTrips.getUpcoming(
                tripType: any(named: 'tripType'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => Right(testTrips));
          return bloc;
        },
        act: (b) => b.add(const LoadUpcomingTrips(tripType: TripType.offer)),
        expect: () => [
          isA<SchedulingLoading>()
              .having((s) => s.tripTypeFilter, 'tripTypeFilter', TripType.offer),
          isA<SchedulingLoaded>()
              .having((s) => s.upcomingTrips.length, 'upcomingTrips.length', 2),
        ],
      );
    });

    group('SelectTrip', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'updates selected trip',
        build: () => bloc,
        seed: () => SchedulingLoaded(myTrips: testTrips),
        act: (b) => b.add(SelectTrip(testTrips[0])),
        expect: () => [
          isA<SchedulingLoaded>()
              .having((s) => s.selectedTrip?.id, 'selectedTrip.id', 'trip-1'),
        ],
      );
    });

    group('ClearSelectedTrip', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'clears selected trip',
        build: () => bloc,
        seed: () => SchedulingLoaded(
          myTrips: testTrips,
          selectedTrip: testTrips[0],
        ),
        act: (b) => b.add(const ClearSelectedTrip()),
        expect: () => [
          isA<SchedulingLoaded>()
              .having((s) => s.selectedTrip, 'selectedTrip', isNull),
        ],
      );
    });

    group('DeleteTrip', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'emits [TripDeleted] when successful',
        build: () {
          when(() => mockManageScheduledTrip.delete(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => SchedulingLoaded(myTrips: testTrips),
        act: (b) => b.add(const DeleteTrip('trip-1')),
        expect: () => [
          isA<TripDeleted>()
              .having((s) => s.tripId, 'tripId', 'trip-1')
              .having((s) => s.myTrips.length, 'remaining trips', 1),
        ],
        verify: (_) {
          verify(() => mockManageScheduledTrip.delete('trip-1')).called(1);
        },
      );
    });

    group('TripUpdated', () {
      blocTest<SchedulingBloc, SchedulingState>(
        'updates trip in lists',
        build: () => bloc,
        seed: () => SchedulingLoaded(
          myTrips: testTrips,
          upcomingTrips: testTrips,
        ),
        act: (b) => b.add(TripUpdated(testTrips[0].copyWith(seatsQty: 5))),
        expect: () => [
          isA<SchedulingLoaded>()
              .having((s) => s.myTrips.first.seatsQty, 'updated seatsQty', 5),
        ],
      );
    });
  });

  group('ScheduledTrip Entity', () {
    test('isOffer returns true for offer type', () {
      final trip = testTrips[0];
      expect(trip.isOffer, true);
      expect(trip.isRequest, false);
    });

    test('isRequest returns true for request type', () {
      final trip = testTrips[1];
      expect(trip.isOffer, false);
      expect(trip.isRequest, true);
    });

    test('isUpcoming returns true for future active trip', () {
      final trip = testTrips[0];
      expect(trip.isUpcoming, true);
    });

    test('copyWith preserves values', () {
      final trip = testTrips[0];
      final updated = trip.copyWith(seatsQty: 5);
      expect(updated.id, trip.id);
      expect(updated.seatsQty, 5);
    });
  });

  group('TripUser', () {
    test('initials are generated correctly', () {
      const user = TripUser(
        id: 'user-1',
        name: 'Jean Pierre',
        rating: 4.5,
      );
      expect(user.initials, 'JP');
    });

    test('single name returns first character', () {
      const user = TripUser(
        id: 'user-1',
        name: 'Jean',
      );
      expect(user.initials, 'J');
    });
  });
}
