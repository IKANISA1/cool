import 'package:equatable/equatable.dart';

import '../../data/models/station_marker.dart';

/// States for StationLocatorBloc
abstract class StationLocatorState extends Equatable {
  const StationLocatorState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any stations loaded
class StationLocatorInitial extends StationLocatorState {
  const StationLocatorInitial();
}

/// Loading stations
class StationLocatorLoading extends StationLocatorState {
  /// Optional: previous stations while refreshing
  final List<StationMarker>? previousStations;

  const StationLocatorLoading({this.previousStations});

  @override
  List<Object?> get props => [previousStations];
}

/// Stations loaded successfully
class StationLocatorLoaded extends StationLocatorState {
  /// List of station markers
  final List<StationMarker> stations;

  /// All stations before filtering (for restoring after clear)
  final List<StationMarker> allStations;

  /// Currently selected station (if any)
  final StationMarker? selectedStation;

  /// Current station type filter
  final String stationType;

  /// Current search query (if any)
  final String? searchQuery;

  /// Current user latitude
  final double? userLatitude;

  /// Current user longitude
  final double? userLongitude;

  /// Whether more stations are being loaded (pagination)
  final bool isLoadingMore;

  /// Whether there are more stations to load
  final bool hasMore;

  /// Set of favorite station IDs
  final Set<String> favoriteIds;

  /// Active filters (e.g., 'operating_now', 'high_availability')
  final Map<String, bool> filters;

  /// Current sort order: distance, rating, availability, name
  final String sortBy;

  /// Current page for pagination
  final int currentPage;

  const StationLocatorLoaded({
    required this.stations,
    List<StationMarker>? allStations,
    this.selectedStation,
    required this.stationType,
    this.searchQuery,
    this.userLatitude,
    this.userLongitude,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.favoriteIds = const {},
    this.filters = const {},
    this.sortBy = 'distance',
    this.currentPage = 1,
  }) : allStations = allStations ?? stations;

  /// Create a copy with updated values
  StationLocatorLoaded copyWith({
    List<StationMarker>? stations,
    List<StationMarker>? allStations,
    StationMarker? selectedStation,
    bool clearSelectedStation = false,
    String? stationType,
    String? searchQuery,
    bool clearSearchQuery = false,
    double? userLatitude,
    double? userLongitude,
    bool? isLoadingMore,
    bool? hasMore,
    Set<String>? favoriteIds,
    Map<String, bool>? filters,
    String? sortBy,
    int? currentPage,
  }) {
    return StationLocatorLoaded(
      stations: stations ?? this.stations,
      allStations: allStations ?? this.allStations,
      selectedStation:
          clearSelectedStation ? null : (selectedStation ?? this.selectedStation),
      stationType: stationType ?? this.stationType,
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        stations,
        allStations,
        selectedStation,
        stationType,
        searchQuery,
        userLatitude,
        userLongitude,
        isLoadingMore,
        hasMore,
        favoriteIds,
        filters,
        sortBy,
        currentPage,
      ];
}


/// Error loading stations
class StationLocatorError extends StationLocatorState {
  /// Error message
  final String message;

  /// Previous stations (for retry functionality)
  final List<StationMarker>? previousStations;

  const StationLocatorError({
    required this.message,
    this.previousStations,
  });

  @override
  List<Object?> get props => [message, previousStations];
}
