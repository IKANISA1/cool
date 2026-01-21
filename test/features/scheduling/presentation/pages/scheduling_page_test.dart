import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/features/scheduling/domain/entities/scheduled_trip.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_bloc.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_event.dart';
import 'package:ridelink/features/scheduling/presentation/bloc/scheduling_state.dart';
import 'package:ridelink/features/scheduling/presentation/pages/scheduling_page.dart';

// Mock classes
class MockSchedulingBloc extends MockBloc<SchedulingEvent, SchedulingState>
    implements SchedulingBloc {}

void main() {
  late MockSchedulingBloc mockBloc;

  setUp(() {
    mockBloc = MockSchedulingBloc();
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
  ];

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider<SchedulingBloc>.value(
        value: mockBloc,
        child: const SchedulingPage(),
      ),
    );
  }

  group('SchedulingPage Widget Tests', () {
    testWidgets('shows loading shimmer in initial state', (tester) async {
      when(() => mockBloc.state).thenReturn(const SchedulingInitial());

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(SchedulingPage), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      when(() => mockBloc.state).thenReturn(const SchedulingLoading());

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(SchedulingPage), findsOneWidget);
    });

    testWidgets('shows trips when loaded', (tester) async {
      when(() => mockBloc.state).thenReturn(SchedulingLoaded(
        upcomingTrips: testTrips,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should show trip cards
      expect(find.text('Kigali City Centre'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockBloc.state).thenReturn(const SchedulingError(
        message: 'Failed to load trips',
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.textContaining('error'), findsWidgets);
    });

    testWidgets('shows empty state when no trips', (tester) async {
      when(() => mockBloc.state).thenReturn(const SchedulingLoaded(
        upcomingTrips: [],
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(SchedulingPage), findsOneWidget);
    });

    testWidgets('has FAB for creating new trip', (tester) async {
      when(() => mockBloc.state).thenReturn(const SchedulingLoaded());

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
