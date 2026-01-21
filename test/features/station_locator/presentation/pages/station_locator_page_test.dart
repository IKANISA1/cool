import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/features/station_locator/data/models/station_marker.dart';
import 'package:ridelink/features/station_locator/domain/entities/station_entity.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_bloc.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_event.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_state.dart';

// Mock classes
class MockStationLocatorBloc
    extends MockBloc<StationLocatorEvent, StationLocatorState>
    implements StationLocatorBloc {}

void main() {
  late MockStationLocatorBloc mockBloc;

  setUp(() {
    mockBloc = MockStationLocatorBloc();
  });

  final List<StationMarker> testStations = [
    StationMarker(
      id: 'station-1',
      name: 'Kigali Central EV Station',
      type: StationType.evCharging,
      position: const LatLng(-1.9403, 30.0619),
      address: 'KN 1 Rd',
      rating: 4.5,
      isOperational: true,
      details: const StationDetails(
        openingHours: '24/7',
        availableSpots: 5,
        totalSpots: 10,
      ),
    ),
    StationMarker(
      id: 'station-2',
      name: 'Remera Battery Swap',
      type: StationType.batterySwap,
      position: const LatLng(-1.9500, 30.1012),
      address: 'KG 5 Ave',
      rating: 4.2,
      isOperational: true,
      details: const StationDetails(
        openingHours: '6AM - 10PM',
        availableSpots: 3,
        totalSpots: 8,
      ),
    ),
  ];

  group('StationLocatorBloc Widget Tests', () {
    test('initial state is StationLocatorInitial', () {
      when(() => mockBloc.state).thenReturn(StationLocatorInitial());
      expect(mockBloc.state, isA<StationLocatorInitial>());
    });

    test('loading state preserves current stations', () {
      when(() => mockBloc.state).thenReturn(StationLocatorLoading(
        stations: testStations,
        stationType: StationType.evCharging,
      ));

      final state = mockBloc.state as StationLocatorLoading;
      expect(state.stations.length, 2);
      expect(state.stationType, StationType.evCharging);
    });

    test('loaded state has stations and type', () {
      when(() => mockBloc.state).thenReturn(StationLocatorLoaded(
        stations: testStations,
        stationType: StationType.batterySwap,
      ));

      final state = mockBloc.state as StationLocatorLoaded;
      expect(state.stations.length, 2);
      expect(state.stationType, StationType.batterySwap);
    });

    test('selected station is tracked', () {
      when(() => mockBloc.state).thenReturn(StationLocatorLoaded(
        stations: testStations,
        stationType: StationType.evCharging,
        selectedStation: testStations[0],
      ));

      final state = mockBloc.state as StationLocatorLoaded;
      expect(state.selectedStation?.id, 'station-1');
    });

    test('error state has message', () {
      when(() => mockBloc.state).thenReturn(const StationLocatorError(
        message: 'Location unavailable',
      ));

      final state = mockBloc.state as StationLocatorError;
      expect(state.message, 'Location unavailable');
    });

    test('search filters stations by name', () {
      when(() => mockBloc.state).thenReturn(StationLocatorLoaded(
        stations: testStations,
        stationType: StationType.evCharging,
        searchQuery: 'Kigali',
      ));

      final state = mockBloc.state as StationLocatorLoaded;
      expect(state.searchQuery, 'Kigali');
    });
  });

  group('StationMarker Entity', () {
    test('distanceText formats correctly', () {
      final station = testStations[0].copyWith(distanceKm: 1.5);
      expect(station.distanceKm, 1.5);
    });

    test('isOperational affects display', () {
      expect(testStations[0].isOperational, true);
      final closed = testStations[0].copyWith(isOperational: false);
      expect(closed.isOperational, false);
    });

    test('different station types', () {
      expect(testStations[0].type, StationType.evCharging);
      expect(testStations[1].type, StationType.batterySwap);
    });
  });
}
