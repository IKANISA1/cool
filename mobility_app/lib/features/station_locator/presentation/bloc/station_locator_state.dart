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

  const StationLocatorLoaded({
    required this.stations,
    this.selectedStation,
    required this.stationType,
    this.searchQuery,
    this.userLatitude,
    this.userLongitude,
  });

  /// Create a copy with updated values
  StationLocatorLoaded copyWith({
    List<StationMarker>? stations,
    StationMarker? selectedStation,
    bool clearSelectedStation = false,
    String? stationType,
    String? searchQuery,
    bool clearSearchQuery = false,
    double? userLatitude,
    double? userLongitude,
  }) {
    return StationLocatorLoaded(
      stations: stations ?? this.stations,
      selectedStation:
          clearSelectedStation ? null : (selectedStation ?? this.selectedStation),
      stationType: stationType ?? this.stationType,
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }

  @override
  List<Object?> get props => [
        stations,
        selectedStation,
        stationType,
        searchQuery,
        userLatitude,
        userLongitude,
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
