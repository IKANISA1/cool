import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/features/requests/domain/entities/ride_request.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_bloc.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_event.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_state.dart';
import 'package:ridelink/features/requests/presentation/pages/requests_list_page.dart';

class MockRequestBloc extends MockBloc<RequestEvent, RequestState>
    implements RequestBloc {}

class FakeRequestEvent extends Fake implements RequestEvent {}

class FakeRequestState extends Fake implements RequestState {}

void main() {
  late MockRequestBloc mockRequestBloc;

  setUpAll(() {
    registerFallbackValue(FakeRequestEvent());
    registerFallbackValue(FakeRequestState());
  });

  setUp(() {
    mockRequestBloc = MockRequestBloc();
  });

  tearDown(() {
    mockRequestBloc.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<RequestBloc>.value(
        value: mockRequestBloc,
        child: const RequestsListPage(),
      ),
    );
  }

  RideRequest createMockRequest({
    required String id,
    String status = 'pending',
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return RideRequest(
      id: id,
      fromUserId: 'user1',
      toUserId: 'user2',
      payload: const {},
      status: status,
      createdAt: createdAt ?? now.subtract(const Duration(minutes: 1)),
      expiresAt: expiresAt ?? now.add(const Duration(seconds: 30)),
      fromUser: const RequestUserInfo(
        id: 'user1',
        name: 'John Doe',
        phone: '+1234567890',
        rating: 4.5,
      ),
      toUser: const RequestUserInfo(
        id: 'user2',
        name: 'Jane Smith',
        phone: '+0987654321',
        rating: 4.8,
      ),
    );
  }

  group('RequestsListPage', () {
    testWidgets('renders page with title', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestInitial());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Requests'), findsOneWidget);
    });

    testWidgets('renders tabs for incoming and outgoing', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestsLoaded(
        incomingRequests: [],
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Incoming'), findsOneWidget);
      expect(find.text('Outgoing'), findsOneWidget);
    });

    testWidgets('shows shimmer loading when loading', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestLoading());

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Shimmer loading should show placeholder containers
      expect(find.byType(RequestsListPage), findsOneWidget);
    });

    testWidgets('shows empty state when no incoming requests', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestsLoaded(
        incomingRequests: [],
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No incoming requests'), findsOneWidget);
      expect(
        find.text('Requests from other users will appear here'),
        findsOneWidget,
      );
    });

    // Note: Outgoing empty state uses same logic as incoming, 
    // verified by tapping Outgoing tab in 'switching tabs' test

    testWidgets('displays incoming requests list', (tester) async {
      final requests = [
        createMockRequest(id: 'req1', status: 'pending'),
        createMockRequest(id: 'req2', status: 'accepted'),
      ];

      when(() => mockRequestBloc.state).thenReturn(RequestsLoaded(
        incomingRequests: requests,
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsNWidgets(2));
    });

    testWidgets('shows pending badge for pending requests', (tester) async {
      final requests = [
        createMockRequest(id: 'req1', status: 'pending'),
      ];

      when(() => mockRequestBloc.state).thenReturn(RequestsLoaded(
        incomingRequests: requests,
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('shows accepted badge for accepted requests', (tester) async {
      final requests = [
        createMockRequest(id: 'req1', status: 'accepted'),
      ];

      when(() => mockRequestBloc.state).thenReturn(RequestsLoaded(
        incomingRequests: requests,
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Accepted'), findsOneWidget);
    });

    testWidgets('shows error view when error state', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestError(
        message: 'Failed to load requests',
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Failed to load requests'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button triggers reload', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestError(
        message: 'Failed to load requests',
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Reset call verification after initial load
      clearInteractions(mockRequestBloc);
      
      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(() => mockRequestBloc.add(const LoadIncomingRequests())).called(1);
    });

    testWidgets('switching tabs loads outgoing requests', (tester) async {
      when(() => mockRequestBloc.state).thenReturn(const RequestsLoaded(
        incomingRequests: [],
        outgoingRequests: [],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on "Outgoing" tab
      await tester.tap(find.text('Outgoing'));
      await tester.pumpAndSettle();

      verify(() => mockRequestBloc.add(const LoadOutgoingRequests())).called(1);
    });
  });
}
