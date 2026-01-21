import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../../../core/services/location_service.dart';
import '../../data/models/station_marker.dart';
import '../../domain/entities/battery_swap_station.dart';
import '../../domain/entities/ev_charging_station.dart';
import '../../domain/repositories/station_repository.dart';
import 'station_locator_event.dart';
import 'station_locator_state.dart';

/// BLoC for managing station locator feature
///
/// Handles:
/// - Loading nearby stations (battery swap or EV charging)
/// - Station selection for details view
/// - Location updates
/// - Search and filtering
class StationLocatorBloc extends Bloc<StationLocatorEvent, StationLocatorState> {
  final LocationService _locationService;
  final StationRepository? _repository;
  final _log = Logger('StationLocatorBloc');

  /// Expose location service for map view
  LocationService get locationService => _locationService;

  StationLocatorBloc({
    required LocationService locationService,
    StationRepository? repository,
  })  : _locationService = locationService,
        _repository = repository,
        super(const StationLocatorInitial()) {
    on<LoadNearbyStations>(_onLoadNearbyStations);
    on<RefreshStations>(_onRefreshStations);
    on<SelectStation>(_onSelectStation);
    on<ClearStationSelection>(_onClearStationSelection);
    on<UpdateMapPosition>(_onUpdateMapPosition);
    on<SearchStations>(_onSearchStations);
  }

  /// Handle LoadNearbyStations event
  Future<void> _onLoadNearbyStations(
    LoadNearbyStations event,
    Emitter<StationLocatorState> emit,
  ) async {
    _log.info('Loading ${event.stationType} stations...');

    // Preserve previous stations during refresh
    final previousStations = state is StationLocatorLoaded
        ? (state as StationLocatorLoaded).stations
        : null;

    emit(StationLocatorLoading(previousStations: previousStations));

    try {
      // Get user's current location if not provided
      double latitude = event.latitude ?? 0;
      double longitude = event.longitude ?? 0;

      if (event.latitude == null || event.longitude == null) {
        final position = await _locationService.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      List<StationMarker> stations;

      // Use repository if available, otherwise fall back to mock data
      if (_repository != null) {
        stations = await _loadStationsFromRepository(
          event.stationType,
          latitude,
          longitude,
        );
      } else {
        // Fall back to mock data for UI testing
        stations = _getMockStations(event.stationType);
      }

      _log.info('Loaded ${stations.length} stations');

      emit(StationLocatorLoaded(
        stations: stations,
        stationType: event.stationType,
        userLatitude: latitude,
        userLongitude: longitude,
      ));
    } catch (e, stackTrace) {
      _log.severe('Failed to load stations', e, stackTrace);
      emit(StationLocatorError(
        message: 'Failed to load stations: ${e.toString()}',
        previousStations: previousStations,
      ));
    }
  }

  /// Load stations from repository
  Future<List<StationMarker>> _loadStationsFromRepository(
    String stationType,
    double latitude,
    double longitude,
  ) async {
    if (stationType == 'battery_swap') {
      final result = await _repository!.getNearbyBatterySwapStations(
        latitude: latitude,
        longitude: longitude,
      );
      return result.fold(
        (error) => throw Exception(error),
        (stations) => stations.map((s) => StationMarker.fromBatterySwap(s)).toList(),
      );
    } else {
      final result = await _repository!.getNearbyEVChargingStations(
        latitude: latitude,
        longitude: longitude,
      );
      return result.fold(
        (error) => throw Exception(error),
        (stations) => stations.map((s) => StationMarker.fromEVCharging(s)).toList(),
      );
    }

  }

  /// Handle RefreshStations event
  Future<void> _onRefreshStations(
    RefreshStations event,
    Emitter<StationLocatorState> emit,
  ) async {
    if (state is StationLocatorLoaded) {
      final currentState = state as StationLocatorLoaded;
      add(LoadNearbyStations(
        stationType: currentState.stationType,
        latitude: currentState.userLatitude,
        longitude: currentState.userLongitude,
      ));
    }
  }

  /// Handle SelectStation event
  void _onSelectStation(
    SelectStation event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is StationLocatorLoaded) {
      final currentState = state as StationLocatorLoaded;
      final selectedStation = currentState.stations.firstWhere(
        (s) => s.id == event.stationId,
        orElse: () => currentState.stations.first,
      );

      emit(currentState.copyWith(selectedStation: selectedStation));
    }
  }

  /// Handle ClearStationSelection event
  void _onClearStationSelection(
    ClearStationSelection event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is StationLocatorLoaded) {
      final currentState = state as StationLocatorLoaded;
      emit(currentState.copyWith(clearSelectedStation: true));
    }
  }

  /// Handle UpdateMapPosition event
  void _onUpdateMapPosition(
    UpdateMapPosition event,
    Emitter<StationLocatorState> emit,
  ) {
    // Could be used to reload stations when map moves significantly
    _log.fine('Map position updated: ${event.latitude}, ${event.longitude}');
  }

  /// Handle SearchStations event
  void _onSearchStations(
    SearchStations event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is StationLocatorLoaded) {
      final currentState = state as StationLocatorLoaded;
      
      if (event.query.isEmpty) {
        emit(currentState.copyWith(clearSearchQuery: true));
        return;
      }

      // Filter stations by search query
      final filteredStations = currentState.stations.where((station) {
        final query = event.query.toLowerCase();
        return station.name.toLowerCase().contains(query) ||
            (station.brand?.toLowerCase().contains(query) ?? false) ||
            (station.network?.toLowerCase().contains(query) ?? false) ||
            (station.details['address']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();

      emit(currentState.copyWith(
        stations: filteredStations,
        searchQuery: event.query,
      ));
    }
  }

  /// Generate mock stations for UI testing
  ///
  /// TODO: Replace with actual API integration
  List<StationMarker> _getMockStations(String stationType) {
    final List<StationMarker> markers = [];

    if (stationType == 'battery_swap' || stationType == 'all') {
      // Mock battery swap stations in Kigali
      final batterySwapStations = [
        const BatterySwapStation(
          id: 'bs_1',
          name: 'Ampersand Kigali Downtown',
          latitude: -1.9441,
          longitude: 30.0619,
          address: 'KN 5 Rd, Kigali',
          brand: 'Ampersand',
          batteriesAvailable: 8,
          totalCapacity: 10,
          averageRating: 4.5,
          isOperational: true,
        ),
        const BatterySwapStation(
          id: 'bs_2',
          name: 'Spiro Nyabugogo Station',
          latitude: -1.9350,
          longitude: 30.0550,
          address: 'Nyabugogo, Kigali',
          brand: 'Spiro',
          batteriesAvailable: 3,
          totalCapacity: 8,
          averageRating: 4.2,
          isOperational: true,
        ),
        const BatterySwapStation(
          id: 'bs_3',
          name: 'Ampersand Kimironko',
          latitude: -1.9380,
          longitude: 30.1050,
          address: 'Kimironko, Kigali',
          brand: 'Ampersand',
          batteriesAvailable: 0,
          totalCapacity: 12,
          averageRating: 4.7,
          isOperational: true,
        ),
        const BatterySwapStation(
          id: 'bs_4',
          name: 'Kigali Heights Station',
          latitude: -1.9530,
          longitude: 30.0920,
          address: 'Kigali Heights, KG 7 Ave',
          brand: 'Ampersand',
          batteriesAvailable: 6,
          totalCapacity: 8,
          averageRating: 4.8,
          isOperational: false,
        ),
      ];

      markers.addAll(
        batterySwapStations.map((s) => StationMarker.fromBatterySwap(s)),
      );
    }

    if (stationType == 'ev_charging' || stationType == 'all') {
      // Mock EV charging stations in Kigali
      final evChargingStations = [
        const EVChargingStation(
          id: 'ev_1',
          name: 'Kigali Convention Centre',
          latitude: -1.9570,
          longitude: 30.0645,
          address: 'KG 2 Roundabout, Kigali',
          network: 'ChargePoint',
          availablePorts: 4,
          totalPorts: 6,
          connectorTypes: [
            ConnectorType(type: 'Type2', count: 4),
            ConnectorType(type: 'CCS', count: 2),
          ],
          maxPowerKw: 50,
          averageRating: 4.6,
          isOperational: true,
          is24Hours: true,
        ),
        const EVChargingStation(
          id: 'ev_2',
          name: 'Kigali Airport EV Station',
          latitude: -1.9686,
          longitude: 30.1395,
          address: 'Kigali International Airport',
          network: 'Volkswagen',
          availablePorts: 2,
          totalPorts: 4,
          connectorTypes: [
            ConnectorType(type: 'CCS', count: 2),
            ConnectorType(type: 'CHAdeMO', count: 2),
          ],
          maxPowerKw: 150,
          averageRating: 4.3,
          isOperational: true,
          is24Hours: true,
        ),
        const EVChargingStation(
          id: 'ev_3',
          name: 'City Centre Mall Charging',
          latitude: -1.9480,
          longitude: 30.0580,
          address: 'City Centre Mall, Kigali',
          network: 'Local Grid',
          availablePorts: 1,
          totalPorts: 2,
          connectorTypes: [
            ConnectorType(type: 'Type2', count: 2),
          ],
          maxPowerKw: 22,
          averageRating: 4.0,
          isOperational: true,
        ),
      ];

      markers.addAll(
        evChargingStations.map((s) => StationMarker.fromEVCharging(s)),
      );
    }

    return markers;
  }
}
