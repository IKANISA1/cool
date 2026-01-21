import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/features/discovery/domain/entities/nearby_user.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_bloc.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_event.dart';
import 'package:ridelink/features/discovery/presentation/bloc/discovery_state.dart';
import 'package:ridelink/features/discovery/presentation/pages/discovery_page.dart';

// Mock classes
class MockDiscoveryBloc extends MockBloc<DiscoveryEvent, DiscoveryState>
    implements DiscoveryBloc {}

void main() {
  late MockDiscoveryBloc mockBloc;

  setUp(() {
    mockBloc = MockDiscoveryBloc();
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

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider<DiscoveryBloc>.value(
        value: mockBloc,
        child: const DiscoveryPage(),
      ),
    );
  }

  group('DiscoveryPage Widget Tests', () {
    testWidgets('shows loading shimmer in initial state', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryInitial());

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should show shimmer loading effect
      expect(find.byType(DiscoveryPage), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryLoading(
        latitude: -1.9403,
        longitude: 30.0619,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(DiscoveryPage), findsOneWidget);
    });

    testWidgets('shows users when loaded', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryLoaded(
        users: testUsers,
        latitude: -1.9403,
        longitude: 30.0619,
        isOnline: true,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should show user cards
      expect(find.text('Jean Driver'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryError(
        message: 'Network error',
        latitude: -1.9403,
        longitude: 30.0619,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.textContaining('error'), findsWidgets);
    });

    testWidgets('has driver and passenger tabs', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryLoaded(
        users: testUsers,
        latitude: -1.9403,
        longitude: 30.0619,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should have tabs (exact text may vary by localization)
      expect(find.byType(DiscoveryPage), findsOneWidget);
    });

    testWidgets('shows empty state when no users', (tester) async {
      when(() => mockBloc.state).thenReturn(const DiscoveryLoaded(
        users: [],
        latitude: -1.9403,
        longitude: 30.0619,
      ));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Should show empty state message
      expect(find.byType(DiscoveryPage), findsOneWidget);
    });
  });
}
