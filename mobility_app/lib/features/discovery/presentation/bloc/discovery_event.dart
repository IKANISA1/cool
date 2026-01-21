import 'package:equatable/equatable.dart';

/// Base class for all discovery events
abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Load nearby users with current filters
class LoadNearbyUsers extends DiscoveryEvent {
  /// Filter by role: 'driver', 'passenger', or null for all
  final String? role;

  /// Search query for filtering users
  final String? searchQuery;

  /// Filter by vehicle categories
  final List<String>? vehicleFilters;

  /// Force refresh (ignore cache)
  final bool forceRefresh;

  const LoadNearbyUsers({
    this.role,
    this.searchQuery,
    this.vehicleFilters,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [role, searchQuery, vehicleFilters, forceRefresh];
}

/// Load more users for pagination
class LoadMoreUsers extends DiscoveryEvent {
  const LoadMoreUsers();
}

/// Toggle user's online/offline status
class ToggleOnlineStatusEvent extends DiscoveryEvent {
  final bool isOnline;

  const ToggleOnlineStatusEvent(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}

/// Update user's current location
class UpdateLocationEvent extends DiscoveryEvent {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;

  const UpdateLocationEvent({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy, heading, speed];
}

/// Search users by name
class SearchUsersEvent extends DiscoveryEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Apply vehicle type filters
class ApplyFiltersEvent extends DiscoveryEvent {
  final List<String> vehicleCategories;

  const ApplyFiltersEvent(this.vehicleCategories);

  @override
  List<Object?> get props => [vehicleCategories];
}

/// Subscribe to realtime updates
class SubscribeToUpdates extends DiscoveryEvent {
  const SubscribeToUpdates();
}

/// Unsubscribe from realtime updates
class UnsubscribeFromUpdates extends DiscoveryEvent {
  const UnsubscribeFromUpdates();
}

/// New nearby users received from stream
class NearbyUsersUpdated extends DiscoveryEvent {
  final List<dynamic> users;

  const NearbyUsersUpdated(this.users);

  @override
  List<Object?> get props => [users];
}

/// Refresh the list
class RefreshNearbyUsers extends DiscoveryEvent {
  const RefreshNearbyUsers();
}
