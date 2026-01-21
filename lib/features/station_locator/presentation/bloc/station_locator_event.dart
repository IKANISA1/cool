import 'package:equatable/equatable.dart';

/// Events for StationLocatorBloc
abstract class StationLocatorEvent extends Equatable {
  const StationLocatorEvent();

  @override
  List<Object?> get props => [];
}

/// Load nearby stations
class LoadNearbyStations extends StationLocatorEvent {
  /// Type of stations to load: 'battery_swap', 'ev_charging', or 'all'
  final String stationType;

  /// Optional latitude to search from (uses current location if null)
  final double? latitude;

  /// Optional longitude to search from (uses current location if null)
  final double? longitude;

  /// Search radius in kilometers (default: 10km)
  final double radiusKm;

  const LoadNearbyStations({
    required this.stationType,
    this.latitude,
    this.longitude,
    this.radiusKm = 10.0,
  });

  @override
  List<Object?> get props => [stationType, latitude, longitude, radiusKm];
}

/// Refresh stations (pull-to-refresh / reload)
class RefreshStations extends StationLocatorEvent {
  const RefreshStations();
}

/// Select a specific station (for showing details)
class SelectStation extends StationLocatorEvent {
  final String stationId;

  const SelectStation({required this.stationId});

  @override
  List<Object?> get props => [stationId];
}

/// Clear station selection
class ClearStationSelection extends StationLocatorEvent {
  const ClearStationSelection();
}

/// Update map camera position
class UpdateMapPosition extends StationLocatorEvent {
  final double latitude;
  final double longitude;
  final double zoom;

  const UpdateMapPosition({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  @override
  List<Object?> get props => [latitude, longitude, zoom];
}

/// Search stations by name or address
class SearchStations extends StationLocatorEvent {
  final String query;

  const SearchStations({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Load more stations for pagination
class LoadMoreStations extends StationLocatorEvent {
  const LoadMoreStations();
}

/// Toggle a filter (operating_now, high_availability)
class ToggleFilter extends StationLocatorEvent {
  final String key;
  final bool value;

  const ToggleFilter({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}

/// Toggle favorite status for a station
class ToggleFavorite extends StationLocatorEvent {
  final String stationType;
  final String stationId;

  const ToggleFavorite({required this.stationType, required this.stationId});

  @override
  List<Object?> get props => [stationType, stationId];
}

/// Clear all active filters
class ClearFilters extends StationLocatorEvent {
  const ClearFilters();
}

/// Update sort order
class UpdateSortBy extends StationLocatorEvent {
  final String sortBy; // distance, rating, availability, name

  const UpdateSortBy({required this.sortBy});

  @override
  List<Object?> get props => [sortBy];
}
