import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ridelink/core/services/location_service.dart';
import 'package:ridelink/features/station_locator/data/models/station_marker.dart';
import 'package:ridelink/features/station_locator/domain/entities/battery_swap_station.dart';
import 'package:ridelink/features/station_locator/domain/repositories/station_repository.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_bloc.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_event.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_state.dart';

// Mock classes
class MockLocationService extends Mock implements LocationService {}
class MockStationRepository extends Mock implements StationRepository {}

void main() {
  late StationLocatorBloc bloc;
  late MockLocationService mockLocationService;
  late MockStationRepository mockStationRepository;

  setUp(() {
    mockLocationService = MockLocationService();
    mockStationRepository = MockStationRepository();

    bloc = StationLocatorBloc(
      locationService: mockLocationService,
      repository: mockStationRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const testBatterySwapStations = [
    BatterySwapStation(
      id: 'bs_1',
      name: 'Ampersand Downtown',
      latitude: -1.9403,
      longitude: 30.0619,
      address: 'KN 5 Rd, Kigali',
      brand: 'Ampersand',
      batteriesAvailable: 8,
      totalCapacity: 10,
      averageRating: 4.5,
      isOperational: true,
    ),
    BatterySwapStation(
      id: 'bs_2',
      name: 'Spiro Nyabugogo',
      latitude: -1.9350,
      longitude: 30.0550,
      address: 'Nyabugogo, Kigali',
      brand: 'Spiro',
      batteriesAvailable: 3,
      totalCapacity: 8,
      averageRating: 4.2,
      isOperational: true,
    ),
  ];

  final testPosition = Position(
    latitude: -1.9403,
    longitude: 30.0619,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 10.0,
    altitude: 1500.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  group('StationLocatorBloc', () {
    test('initial state is StationLocatorInitial', () {
      expect(bloc.state, const StationLocatorInitial());
    });

    group('LoadNearbyStations', () {
      blocTest<StationLocatorBloc, StationLocatorState>(
        'emits [StationLocatorLoading, StationLocatorLoaded] when successful',
        build: () {
          when(() => mockLocationService.getCurrentPosition(forceRefresh: any(named: 'forceRefresh')))
              .thenAnswer((_) async => testPosition);
          when(() => mockStationRepository.getNearbyBatterySwapStations(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                radiusKm: any(named: 'radiusKm'),
                limit: any(named: 'limit'),
              )).thenAnswer((_) async => const Right(testBatterySwapStations));
          return bloc;
        },
        act: (b) => b.add(const LoadNearbyStations(stationType: 'battery_swap')),
        expect: () => [
          isA<StationLocatorLoading>(),
          isA<StationLocatorLoaded>()
              .having((s) => s.stations.length, 'stations.length', 2)
              .having((s) => s.stationType, 'stationType', 'battery_swap'),
        ],
        verify: (_) {
          verify(() => mockLocationService.getCurrentPosition(forceRefresh: any(named: 'forceRefresh'))).called(1);
          verify(() => mockStationRepository.getNearbyBatterySwapStations(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                radiusKm: any(named: 'radiusKm'),
                limit: any(named: 'limit'),
              )).called(1);
        },
      );

      blocTest<StationLocatorBloc, StationLocatorState>(
        'emits [StationLocatorLoading, StationLocatorError] when location fails',
        build: () {
          when(() => mockLocationService.getCurrentPosition(forceRefresh: any(named: 'forceRefresh')))
              .thenThrow(Exception('Location permission denied'));
          return bloc;
        },
        act: (b) => b.add(const LoadNearbyStations(stationType: 'ev_charging')),
        expect: () => [
          isA<StationLocatorLoading>(),
          isA<StationLocatorError>()
              .having((s) => s.message, 'message', contains('Location')),
        ],
      );

      blocTest<StationLocatorBloc, StationLocatorState>(
        'uses mock data when repository is null',
        build: () {
          // Create bloc without repository
          final blocWithoutRepo = StationLocatorBloc(
            locationService: mockLocationService,
            // No repository - will use mock data
          );
          when(() => mockLocationService.getCurrentPosition(forceRefresh: any(named: 'forceRefresh')))
              .thenAnswer((_) async => testPosition);
          return blocWithoutRepo;
        },
        act: (b) => b.add(const LoadNearbyStations(stationType: 'battery_swap')),
        expect: () => [
          isA<StationLocatorLoading>(),
          isA<StationLocatorLoaded>()
              .having((s) => s.stations.isNotEmpty, 'has mock stations', true),
        ],
      );
    });

    group('SelectStation', () {
      final testMarkers = testBatterySwapStations
          .map((s) => StationMarker.fromBatterySwap(s))
          .toList();

      blocTest<StationLocatorBloc, StationLocatorState>(
        'emits state with selected station',
        build: () => bloc,
        seed: () => StationLocatorLoaded(
          stations: testMarkers,
          allStations: testMarkers,
          stationType: 'battery_swap',
          userLatitude: -1.9403,
          userLongitude: 30.0619,
        ),
        act: (b) => b.add(const SelectStation(stationId: 'bs_1')),
        expect: () => [
          isA<StationLocatorLoaded>()
              .having((s) => s.selectedStation?.id, 'selectedStation.id', 'bs_1'),
        ],
      );
    });

    group('ClearStationSelection', () {
      final testMarkers = testBatterySwapStations
          .map((s) => StationMarker.fromBatterySwap(s))
          .toList();

      blocTest<StationLocatorBloc, StationLocatorState>(
        'emits state with null selected station',
        build: () => bloc,
        seed: () => StationLocatorLoaded(
          stations: testMarkers,
          allStations: testMarkers,
          stationType: 'battery_swap',
          selectedStation: testMarkers[0],
          userLatitude: -1.9403,
          userLongitude: 30.0619,
        ),
        act: (b) => b.add(const ClearStationSelection()),
        expect: () => [
          isA<StationLocatorLoaded>()
              .having((s) => s.selectedStation, 'selectedStation', isNull),
        ],
      );
    });

    group('SearchStations', () {
      final testMarkers = testBatterySwapStations
          .map((s) => StationMarker.fromBatterySwap(s))
          .toList();

      blocTest<StationLocatorBloc, StationLocatorState>(
        'filters stations by name',
        build: () => bloc,
        seed: () => StationLocatorLoaded(
          stations: testMarkers,
          allStations: testMarkers,
          stationType: 'battery_swap',
          userLatitude: -1.9403,
          userLongitude: 30.0619,
        ),
        act: (b) => b.add(const SearchStations(query: 'Ampersand')),
        expect: () => [
          isA<StationLocatorLoaded>()
              .having((s) => s.stations.length, 'filtered count', 1)
              .having((s) => s.searchQuery, 'searchQuery', 'Ampersand'),
        ],
      );

      blocTest<StationLocatorBloc, StationLocatorState>(
        'restores all stations when query is empty',
        build: () => bloc,
        seed: () => StationLocatorLoaded(
          stations: [testMarkers[0]], // Only one visible
          allStations: testMarkers, // But all are stored
          stationType: 'battery_swap',
          searchQuery: 'Ampersand',
          userLatitude: -1.9403,
          userLongitude: 30.0619,
        ),
        act: (b) => b.add(const SearchStations(query: '')),
        expect: () => [
          isA<StationLocatorLoaded>()
              .having((s) => s.stations.length, 'restored count', 2)
              .having((s) => s.searchQuery, 'cleared query', isNull),
        ],
      );
    });

    group('UpdateSortBy', () {
      final testMarkers = testBatterySwapStations
          .map((s) => StationMarker.fromBatterySwap(s))
          .toList();

      blocTest<StationLocatorBloc, StationLocatorState>(
        'sorts stations by name',
        build: () => bloc,
        seed: () => StationLocatorLoaded(
          stations: testMarkers,
          allStations: testMarkers,
          stationType: 'battery_swap',
          userLatitude: -1.9403,
          userLongitude: 30.0619,
        ),
        act: (b) => b.add(const UpdateSortBy(sortBy: 'name')),
        expect: () => [
          isA<StationLocatorLoaded>()
              .having((s) => s.sortBy, 'sortBy', 'name')
              .having((s) => s.stations.first.name, 'first by name', 'Ampersand Downtown'),
        ],
      );
    });
  });

  group('StationMarker', () {
    test('fromBatterySwap creates marker correctly', () {
      const station = BatterySwapStation(
        id: 'test-id',
        name: 'Test Station',
        latitude: -1.9403,
        longitude: 30.0619,
        address: 'Test Address',
        brand: 'TestBrand',
        batteriesAvailable: 5,
        totalCapacity: 10,
        averageRating: 4.5,
        isOperational: true,
      );

      final marker = StationMarker.fromBatterySwap(station);

      expect(marker.id, 'test-id');
      expect(marker.name, 'Test Station');
      expect(marker.stationType, 'battery_swap');
      expect(marker.position, const LatLng(-1.9403, 30.0619));
      expect(marker.brand, 'TestBrand');
      expect(marker.rating, 4.5);
      expect(marker.isOperational, true);
      expect(marker.isBatterySwap, true);
      expect(marker.isEVCharging, false);
    });

    test('displayName prefers brand over name', () {
      final marker = StationMarker(
        id: '1',
        name: 'Generic Station',
        stationType: 'battery_swap',
        position: const LatLng(-1.9403, 30.0619),
        brand: 'Ampersand',
        rating: 4.0,
        isOperational: true,
        details: {},
      );

      expect(marker.displayName, 'Ampersand');
    });

    test('availabilityText returns correct status', () {
      final highAvail = StationMarker(
        id: '1',
        name: 'Station',
        stationType: 'battery_swap',
        position: const LatLng(-1.9403, 30.0619),
        availabilityPercent: 80.0,
        rating: 4.0,
        isOperational: true,
        details: {},
      );

      final lowAvail = StationMarker(
        id: '2',
        name: 'Station',
        stationType: 'battery_swap',
        position: const LatLng(-1.9403, 30.0619),
        availabilityPercent: 20.0,
        rating: 4.0,
        isOperational: true,
        details: {},
      );

      expect(highAvail.availabilityText, 'High availability');
      expect(lowAvail.availabilityText, 'Very low availability');
    });
  });
}
