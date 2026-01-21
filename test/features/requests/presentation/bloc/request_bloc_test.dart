import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/error/failures.dart';
import 'package:ridelink/features/requests/domain/entities/ride_request.dart';
import 'package:ridelink/features/requests/domain/repositories/request_repository.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_bloc.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_event.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_state.dart';

// Mock classes
class MockRequestRepository extends Mock implements RequestRepository {}

// Fake classes for registerFallbackValue
class FakeSendRequestParams extends Fake implements SendRequestParams {}

void main() {
  late RequestBloc bloc;
  late MockRequestRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeSendRequestParams());
  });

  setUp(() {
    mockRepository = MockRequestRepository();

    bloc = RequestBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  final now = DateTime.now();
  final testRequest = RideRequest(
    id: 'req-1',
    fromUserId: 'user-1',
    toUserId: 'user-2',
    payload: const {'note': 'Need a ride to downtown'},
    status: 'pending',
    createdAt: now,
    expiresAt: now.add(const Duration(seconds: 60)),
  );

  final testIncoming = [
    RideRequest(
      id: 'req-2',
      fromUserId: 'user-3',
      toUserId: 'user-1',
      payload: const {},
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(const Duration(seconds: 30)),
    ),
  ];

  final testOutgoing = [testRequest];

  group('RequestBloc', () {
    test('initial state is RequestInitial', () {
      expect(bloc.state, const RequestInitial());
    });

    group('SendRequest', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestSending, RequestSent] when successful',
        build: () {
          when(() => mockRepository.sendRequest(any()))
              .thenAnswer((_) async => Right(testRequest));
          return bloc;
        },
        act: (b) => b.add(const SendRequest(toUserId: 'user-2')),
        expect: () => [
          isA<RequestSending>(),
          isA<RequestSent>()
              .having((s) => s.request.id, 'request.id', 'req-1'),
        ],
        verify: (_) {
          verify(() => mockRepository.sendRequest(any())).called(1);
        },
      );

      blocTest<RequestBloc, RequestState>(
        'emits [RequestSending, RequestError] when fails',
        build: () {
          when(() => mockRepository.sendRequest(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'User offline')));
          return bloc;
        },
        act: (b) => b.add(const SendRequest(toUserId: 'user-2')),
        expect: () => [
          isA<RequestSending>(),
          isA<RequestError>()
              .having((s) => s.message, 'message', 'User offline'),
        ],
      );
    });

    group('AcceptRequest', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestLoading, RequestAccepted] when successful',
        build: () {
          when(() => mockRepository.acceptRequest(any())).thenAnswer(
              (_) async => Right(testRequest.copyWith(status: 'accepted')));
          return bloc;
        },
        act: (b) => b.add(const AcceptRequest('req-1')),
        expect: () => [
          isA<RequestLoading>(),
          isA<RequestAccepted>()
              .having((s) => s.request.status, 'status', 'accepted'),
        ],
        verify: (_) {
          verify(() => mockRepository.acceptRequest('req-1')).called(1);
        },
      );

      blocTest<RequestBloc, RequestState>(
        'emits [RequestLoading, RequestError] when fails',
        build: () {
          when(() => mockRepository.acceptRequest(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'Request expired')));
          return bloc;
        },
        act: (b) => b.add(const AcceptRequest('req-1')),
        expect: () => [
          isA<RequestLoading>(),
          isA<RequestError>()
              .having((s) => s.message, 'message', 'Request expired'),
        ],
      );
    });

    group('DenyRequest', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestLoading, RequestDenied] when successful',
        build: () {
          when(() => mockRepository.denyRequest(any())).thenAnswer(
              (_) async => Right(testRequest.copyWith(status: 'denied')));
          return bloc;
        },
        act: (b) => b.add(const DenyRequest('req-1')),
        expect: () => [
          isA<RequestLoading>(),
          isA<RequestDenied>()
              .having((s) => s.request.status, 'status', 'denied'),
        ],
        verify: (_) {
          verify(() => mockRepository.denyRequest('req-1')).called(1);
        },
      );
    });

    group('LoadIncomingRequests', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestLoading, RequestsLoaded] when successful',
        build: () {
          when(() => mockRepository.getIncomingRequests())
              .thenAnswer((_) async => Right(testIncoming));
          return bloc;
        },
        act: (b) => b.add(const LoadIncomingRequests()),
        expect: () => [
          isA<RequestLoading>(),
          isA<RequestsLoaded>()
              .having((s) => s.incomingRequests.length, 'incoming count', 1),
        ],
        verify: (_) {
          verify(() => mockRepository.getIncomingRequests()).called(1);
        },
      );
    });

    group('LoadOutgoingRequests', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestLoading, RequestsLoaded] when successful',
        build: () {
          when(() => mockRepository.getOutgoingRequests())
              .thenAnswer((_) async => Right(testOutgoing));
          return bloc;
        },
        act: (b) => b.add(const LoadOutgoingRequests()),
        expect: () => [
          isA<RequestLoading>(),
          isA<RequestsLoaded>()
              .having((s) => s.outgoingRequests.length, 'outgoing count', 1),
        ],
        verify: (_) {
          verify(() => mockRepository.getOutgoingRequests()).called(1);
        },
      );
    });

    group('CancelRequest', () {
      blocTest<RequestBloc, RequestState>(
        'emits [RequestCancelled] when successful',
        build: () {
          when(() => mockRepository.cancelRequest(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (b) => b.add(const CancelRequest('req-1')),
        expect: () => [
          isA<RequestCancelled>(),
        ],
        verify: (_) {
          verify(() => mockRepository.cancelRequest('req-1')).called(1);
        },
      );
    });
  });

  group('RideRequest Entity', () {
    test('isPending returns true for pending status', () {
      expect(testRequest.isPending, true);
    });

    test('isAccepted returns true for accepted status', () {
      final accepted = testRequest.copyWith(status: 'accepted');
      expect(accepted.isAccepted, true);
    });

    test('secondsRemaining returns positive for future expiry', () {
      expect(testRequest.secondsRemaining, greaterThan(0));
    });

    test('progress returns value between 0 and 1', () {
      expect(testRequest.progress, greaterThanOrEqualTo(0));
      expect(testRequest.progress, lessThanOrEqualTo(1));
    });

    test('note returns payload note', () {
      expect(testRequest.note, 'Need a ride to downtown');
    });

    test('copyWith preserves values', () {
      final updated = testRequest.copyWith(status: 'accepted');
      expect(updated.id, testRequest.id);
      expect(updated.status, 'accepted');
    });
  });

  group('RequestUserInfo', () {
    test('initials are generated correctly', () {
      const user = RequestUserInfo(
        id: 'user-1',
        name: 'Jean Pierre',
        phone: '+250788000001',
        rating: 4.5,
      );
      expect(user.initials, 'JP');
    });

    test('single name returns first character', () {
      const user = RequestUserInfo(
        id: 'user-1',
        name: 'Jean',
        phone: '+250788000001',
        rating: 4.5,
      );
      expect(user.initials, 'J');
    });
  });
}
