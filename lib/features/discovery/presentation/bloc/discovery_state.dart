import 'package:equatable/equatable.dart';

import '../../domain/entities/nearby_user.dart';

/// Base class for all discovery states
abstract class DiscoveryState extends Equatable {
  /// List of nearby users
  final List<NearbyUser> users;

  /// Whether user is currently online
  final bool isOnline;

  /// Current role filter: 'driver', 'passenger', or null
  final String? roleFilter;

  /// Current vehicle category filters
  final List<String> vehicleFilters;

  /// Current search query
  final String? searchQuery;

  /// Whether more results are available (pagination)
  final bool hasMore;

  /// Current page number
  final int currentPage;

  /// User's current latitude
  final double? latitude;

  /// User's current longitude
  final double? longitude;

  const DiscoveryState({
    this.users = const [],
    this.isOnline = false,
    this.roleFilter,
    this.vehicleFilters = const [],
    this.searchQuery,
    this.hasMore = false,
    this.currentPage = 1,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        users,
        isOnline,
        roleFilter,
        vehicleFilters,
        searchQuery,
        hasMore,
        currentPage,
        latitude,
        longitude,
      ];

  /// Copy with updated fields
  DiscoveryState copyWith({
    List<NearbyUser>? users,
    bool? isOnline,
    String? roleFilter,
    List<String>? vehicleFilters,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
    double? latitude,
    double? longitude,
  });
}

/// Initial state before any data is loaded
class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial() : super();

  @override
  DiscoveryState copyWith({
    List<NearbyUser>? users,
    bool? isOnline,
    String? roleFilter,
    List<String>? vehicleFilters,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryLoaded(
      users: users ?? this.users,
      isOnline: isOnline ?? this.isOnline,
      roleFilter: roleFilter ?? this.roleFilter,
      vehicleFilters: vehicleFilters ?? this.vehicleFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Loading state while fetching data
class DiscoveryLoading extends DiscoveryState {
  /// Whether this is loading more items (pagination)
  final bool isLoadingMore;

  const DiscoveryLoading({
    super.users,
    super.isOnline,
    super.roleFilter,
    super.vehicleFilters,
    super.searchQuery,
    super.hasMore,
    super.currentPage,
    super.latitude,
    super.longitude,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [...super.props, isLoadingMore];

  @override
  DiscoveryState copyWith({
    List<NearbyUser>? users,
    bool? isOnline,
    String? roleFilter,
    List<String>? vehicleFilters,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryLoading(
      users: users ?? this.users,
      isOnline: isOnline ?? this.isOnline,
      roleFilter: roleFilter ?? this.roleFilter,
      vehicleFilters: vehicleFilters ?? this.vehicleFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoadingMore: isLoadingMore,
    );
  }
}

/// Successfully loaded nearby users
class DiscoveryLoaded extends DiscoveryState {
  const DiscoveryLoaded({
    super.users,
    super.isOnline,
    super.roleFilter,
    super.vehicleFilters,
    super.searchQuery,
    super.hasMore,
    super.currentPage,
    super.latitude,
    super.longitude,
  });

  @override
  DiscoveryState copyWith({
    List<NearbyUser>? users,
    bool? isOnline,
    String? roleFilter,
    List<String>? vehicleFilters,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryLoaded(
      users: users ?? this.users,
      isOnline: isOnline ?? this.isOnline,
      roleFilter: roleFilter ?? this.roleFilter,
      vehicleFilters: vehicleFilters ?? this.vehicleFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// Error state when fetching fails
class DiscoveryError extends DiscoveryState {
  final String message;
  final String? code;

  const DiscoveryError({
    required this.message,
    this.code,
    super.users,
    super.isOnline,
    super.roleFilter,
    super.vehicleFilters,
    super.searchQuery,
    super.hasMore,
    super.currentPage,
    super.latitude,
    super.longitude,
  });

  @override
  List<Object?> get props => [...super.props, message, code];

  @override
  DiscoveryState copyWith({
    List<NearbyUser>? users,
    bool? isOnline,
    String? roleFilter,
    List<String>? vehicleFilters,
    String? searchQuery,
    bool? hasMore,
    int? currentPage,
    double? latitude,
    double? longitude,
  }) {
    return DiscoveryError(
      message: message,
      code: code,
      users: users ?? this.users,
      isOnline: isOnline ?? this.isOnline,
      roleFilter: roleFilter ?? this.roleFilter,
      vehicleFilters: vehicleFilters ?? this.vehicleFilters,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
