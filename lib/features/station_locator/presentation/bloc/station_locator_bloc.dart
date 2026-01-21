import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// - Sorting and pagination
/// - Favorites management
class StationLocatorBloc extends Bloc<StationLocatorEvent, StationLocatorState> {
  final LocationService _locationService;
  final StationRepository? _repository;
  final _log = Logger('StationLocatorBloc');

  static const int _pageSize = 20;
  static const String _favoritesKeyPrefix = 'station_favorites_';

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
    on<LoadMoreStations>(_onLoadMoreStations);
    on<ToggleFilter>(_onToggleFilter);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ClearFilters>(_onClearFilters);
    on<UpdateSortBy>(_onUpdateSortBy);
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

      // Load favorites
      final favoriteIds = await _loadFavorites(event.stationType);

      // Sort stations by default (distance)
      final sortedStations = _sortStations(stations, 'distance', latitude, longitude);

      _log.info('Loaded ${stations.length} stations');

      emit(StationLocatorLoaded(
        stations: sortedStations,
        allStations: sortedStations,
        stationType: event.stationType,
        userLatitude: latitude,
        userLongitude: longitude,
        favoriteIds: favoriteIds,
        hasMore: stations.length >= _pageSize,
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
        // Restore all stations and reapply filters
        final filteredStations = _applyFilters(
          currentState.allStations,
          currentState.filters,
          currentState.favoriteIds,
        );
        emit(currentState.copyWith(
          stations: filteredStations,
          clearSearchQuery: true,
        ));
        return;
      }

      // Filter stations by search query
      final filteredStations = currentState.allStations.where((station) {
        final query = event.query.toLowerCase();
        return station.name.toLowerCase().contains(query) ||
            (station.brand?.toLowerCase().contains(query) ?? false) ||
            (station.network?.toLowerCase().contains(query) ?? false) ||
            (station.details['address']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();

      // Apply other filters on top of search
      final finalStations = _applyFilters(
        filteredStations,
        currentState.filters,
        currentState.favoriteIds,
      );

      emit(currentState.copyWith(
        stations: finalStations,
        searchQuery: event.query,
      ));
    }
  }

  /// Handle LoadMoreStations event (pagination)
  Future<void> _onLoadMoreStations(
    LoadMoreStations event,
    Emitter<StationLocatorState> emit,
  ) async {
    if (state is! StationLocatorLoaded) return;
    
    final currentState = state as StationLocatorLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      // In a real implementation, fetch next page from repository
      // For now, simulate pagination with mock data delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mark as no more data (mock implementation)
      emit(currentState.copyWith(
        isLoadingMore: false,
        hasMore: false,
        currentPage: currentState.currentPage + 1,
      ));
    } catch (e) {
      _log.warning('Failed to load more stations: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Handle ToggleFilter event
  void _onToggleFilter(
    ToggleFilter event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is! StationLocatorLoaded) return;
    
    final currentState = state as StationLocatorLoaded;
    final newFilters = Map<String, bool>.from(currentState.filters);
    newFilters[event.key] = event.value;

    // Reapply all filters
    var filteredStations = currentState.allStations;
    
    // Apply search query if exists
    if (currentState.searchQuery?.isNotEmpty == true) {
      final query = currentState.searchQuery!.toLowerCase();
      filteredStations = filteredStations.where((station) {
        return station.name.toLowerCase().contains(query) ||
            (station.brand?.toLowerCase().contains(query) ?? false) ||
            (station.network?.toLowerCase().contains(query) ?? false) ||
            (station.details['address']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply filters
    filteredStations = _applyFilters(filteredStations, newFilters, currentState.favoriteIds);

    emit(currentState.copyWith(
      stations: filteredStations,
      filters: newFilters,
    ));
  }

  /// Handle ToggleFavorite event
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<StationLocatorState> emit,
  ) async {
    if (state is! StationLocatorLoaded) return;
    
    final currentState = state as StationLocatorLoaded;
    final newFavorites = Set<String>.from(currentState.favoriteIds);

    if (newFavorites.contains(event.stationId)) {
      newFavorites.remove(event.stationId);
    } else {
      newFavorites.add(event.stationId);
    }

    // Persist to storage
    await _saveFavorites(event.stationType, newFavorites);

    // If favorites filter is active, reapply filters
    var stations = currentState.stations;
    if (currentState.filters['favorites'] == true) {
      stations = _applyFilters(
        currentState.allStations,
        currentState.filters,
        newFavorites,
      );
    }

    emit(currentState.copyWith(
      favoriteIds: newFavorites,
      stations: stations,
    ));
  }

  /// Handle ClearFilters event
  void _onClearFilters(
    ClearFilters event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is! StationLocatorLoaded) return;
    
    final currentState = state as StationLocatorLoaded;
    
    emit(currentState.copyWith(
      stations: currentState.allStations,
      filters: {},
      clearSearchQuery: true,
    ));
  }

  /// Handle UpdateSortBy event
  void _onUpdateSortBy(
    UpdateSortBy event,
    Emitter<StationLocatorState> emit,
  ) {
    if (state is! StationLocatorLoaded) return;
    
    final currentState = state as StationLocatorLoaded;
    
    final sortedStations = _sortStations(
      currentState.stations,
      event.sortBy,
      currentState.userLatitude,
      currentState.userLongitude,
    );
    
    final sortedAllStations = _sortStations(
      currentState.allStations,
      event.sortBy,
      currentState.userLatitude,
      currentState.userLongitude,
    );

    emit(currentState.copyWith(
      stations: sortedStations,
      allStations: sortedAllStations,
      sortBy: event.sortBy,
    ));
  }

  /// Apply filters to station list
  List<StationMarker> _applyFilters(
    List<StationMarker> stations,
    Map<String, bool> filters,
    Set<String> favoriteIds,
  ) {
    var result = stations;

    // Filter by favorites
    if (filters['favorites'] == true) {
      result = result.where((s) => favoriteIds.contains(s.id)).toList();
    }

    // Filter by operating status
    if (filters['operating_now'] == true) {
      result = result.where((s) => s.isOperational).toList();
    }

    // Filter by high availability
    if (filters['high_availability'] == true) {
      result = result.where((s) {
        final available = s.isBatterySwap
            ? s.details['batteries_available'] as int? ?? 0
            : s.details['available_ports'] as int? ?? 0;
        return available >= 3;
      }).toList();
    }

    return result;
  }

  /// Sort stations by specified criteria
  List<StationMarker> _sortStations(
    List<StationMarker> stations,
    String sortBy,
    double? userLat,
    double? userLng,
  ) {
    final sorted = List<StationMarker>.from(stations);

    switch (sortBy) {
      case 'distance':
        if (userLat != null && userLng != null) {
          sorted.sort((a, b) {
            final distA = _calculateDistance(userLat, userLng, a.position.latitude, a.position.longitude);
            final distB = _calculateDistance(userLat, userLng, b.position.latitude, b.position.longitude);
            return distA.compareTo(distB);
          });
        }
        break;
      case 'rating':
        sorted.sort((a, b) {
          final ratingA = (a.details['rating'] as double?) ?? 0;
          final ratingB = (b.details['rating'] as double?) ?? 0;
          return ratingB.compareTo(ratingA); // Descending
        });
        break;
      case 'availability':
        sorted.sort((a, b) {
          final availA = a.isBatterySwap
              ? (a.details['batteries_available'] as int?) ?? 0
              : (a.details['available_ports'] as int?) ?? 0;
          final availB = b.isBatterySwap
              ? (b.details['batteries_available'] as int?) ?? 0
              : (b.details['available_ports'] as int?) ?? 0;
          return availB.compareTo(availA); // Descending
        });
        break;
      case 'name':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }

    return sorted;
  }

  /// Simple distance calculation (Haversine approximation)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final latDiff = (lat2 - lat1).abs();
    final lonDiff = (lon2 - lon1).abs();
    return latDiff * latDiff + lonDiff * lonDiff; // Squared distance for sorting
  }

  /// Load favorites from storage
  Future<Set<String>> _loadFavorites(String stationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_favoritesKeyPrefix$stationType';
      final json = prefs.getString(key);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>;
        return list.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      _log.warning('Failed to load favorites: $e');
    }
    return {};
  }

  /// Save favorites to storage
  Future<void> _saveFavorites(String stationType, Set<String> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_favoritesKeyPrefix$stationType';
      await prefs.setString(key, jsonEncode(favorites.toList()));
    } catch (e) {
      _log.warning('Failed to save favorites: $e');
    }
  }

  /// Generate mock stations for UI testing
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
