import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/nearby_user.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../domain/usecases/get_nearby_users.dart';
import '../../domain/usecases/toggle_online_status.dart';
import '../../domain/usecases/update_user_location.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// BLoC for managing discovery/nearby users feature
///
/// Handles:
/// - Loading nearby users with filters
/// - Pagination (infinite scroll)
/// - Realtime updates via Supabase
/// - Online/offline status toggle
/// - Location updates
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final GetNearbyUsers getNearbyUsers;
  final ToggleOnlineStatus toggleOnlineStatus;
  final UpdateUserLocation updateUserLocation;

  final _log = Logger('DiscoveryBloc');

  StreamSubscription? _nearbyUsersSubscription;

  // Default search radius in km
  static const double defaultRadius = 10.0;

  // Page size for pagination
  static const int pageSize = 20;

  DiscoveryBloc({
    required this.getNearbyUsers,
    required this.toggleOnlineStatus,
    required this.updateUserLocation,
  }) : super(const DiscoveryInitial()) {
    on<LoadNearbyUsers>(_onLoadNearbyUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<ToggleOnlineStatusEvent>(_onToggleOnlineStatus);
    on<UpdateLocationEvent>(_onUpdateLocation);
    on<SearchUsersEvent>(_onSearchUsers);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<SubscribeToUpdates>(_onSubscribeToUpdates);
    on<UnsubscribeFromUpdates>(_onUnsubscribeFromUpdates);
    on<NearbyUsersUpdated>(_onNearbyUsersUpdated);
    on<RefreshNearbyUsers>(_onRefreshNearbyUsers);
  }

  @override
  Future<void> close() {
    _nearbyUsersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadNearbyUsers(
    LoadNearbyUsers event,
    Emitter<DiscoveryState> emit,
  ) async {
    _log.info('Loading nearby users: role=${event.role}');

    // Show loading state, but keep existing data
    emit(DiscoveryLoading(
      users: state.users,
      isOnline: state.isOnline,
      roleFilter: event.role,
      vehicleFilters: event.vehicleFilters ?? state.vehicleFilters,
      searchQuery: event.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
    ));

    // Need location to search nearby
    if (state.latitude == null || state.longitude == null) {
      emit(DiscoveryError(
        message: 'Location not available. Please enable location services.',
        users: state.users,
        isOnline: state.isOnline,
        roleFilter: event.role,
        vehicleFilters: event.vehicleFilters ?? state.vehicleFilters,
      ));
      return;
    }

    final params = NearbyUsersParams(
      latitude: state.latitude!,
      longitude: state.longitude!,
      radiusKm: defaultRadius,
      role: event.role,
      vehicleCategories: event.vehicleFilters,
      searchQuery: event.searchQuery,
      page: 1,
      pageSize: pageSize,
    );

    final result = await getNearbyUsers(params);

    result.fold(
      (failure) {
        _log.warning('Failed to load nearby users: ${failure.message}');
        emit(DiscoveryError(
          message: failure.message,
          code: failure.code,
          isOnline: state.isOnline,
          roleFilter: event.role,
          vehicleFilters: event.vehicleFilters ?? state.vehicleFilters,
          searchQuery: event.searchQuery,
          latitude: state.latitude,
          longitude: state.longitude,
        ));
      },
      (result) {
        _log.info('Loaded ${result.users.length} nearby users');
        emit(DiscoveryLoaded(
          users: result.users,
          isOnline: state.isOnline,
          hasMore: result.hasMore,
          currentPage: 1,
          roleFilter: event.role,
          vehicleFilters: event.vehicleFilters ?? state.vehicleFilters,
          searchQuery: event.searchQuery,
          latitude: state.latitude,
          longitude: state.longitude,
        ));
      },
    );
  }

  Future<void> _onLoadMoreUsers(
    LoadMoreUsers event,
    Emitter<DiscoveryState> emit,
  ) async {
    if (state is DiscoveryLoading || !state.hasMore) {
      return;
    }

    _log.info('Loading more users, page ${state.currentPage + 1}');

    emit(DiscoveryLoading(
      users: state.users,
      isOnline: state.isOnline,
      roleFilter: state.roleFilter,
      vehicleFilters: state.vehicleFilters,
      searchQuery: state.searchQuery,
      hasMore: state.hasMore,
      currentPage: state.currentPage,
      latitude: state.latitude,
      longitude: state.longitude,
      isLoadingMore: true,
    ));

    if (state.latitude == null || state.longitude == null) {
      return;
    }

    final params = NearbyUsersParams(
      latitude: state.latitude!,
      longitude: state.longitude!,
      radiusKm: defaultRadius,
      role: state.roleFilter,
      vehicleCategories: state.vehicleFilters.isNotEmpty ? state.vehicleFilters : null,
      searchQuery: state.searchQuery,
      page: state.currentPage + 1,
      pageSize: pageSize,
    );

    final result = await getNearbyUsers(params);

    result.fold(
      (failure) {
        _log.warning('Failed to load more users: ${failure.message}');
        // On error, just go back to loaded state with existing data
        emit(DiscoveryLoaded(
          users: state.users,
          isOnline: state.isOnline,
          hasMore: state.hasMore,
          currentPage: state.currentPage,
          roleFilter: state.roleFilter,
          vehicleFilters: state.vehicleFilters,
          searchQuery: state.searchQuery,
          latitude: state.latitude,
          longitude: state.longitude,
        ));
      },
      (result) {
        _log.info('Loaded ${result.users.length} more users');
        emit(DiscoveryLoaded(
          users: [...state.users, ...result.users],
          isOnline: state.isOnline,
          hasMore: result.hasMore,
          currentPage: state.currentPage + 1,
          roleFilter: state.roleFilter,
          vehicleFilters: state.vehicleFilters,
          searchQuery: state.searchQuery,
          latitude: state.latitude,
          longitude: state.longitude,
        ));
      },
    );
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatusEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    _log.info('Toggling online status to ${event.isOnline}');

    final result = await toggleOnlineStatus(event.isOnline);

    result.fold(
      (failure) {
        _log.warning('Failed to toggle online status: ${failure.message}');
        // Don't change state on failure
      },
      (isOnline) {
        emit(state.copyWith(isOnline: isOnline));
      },
    );
  }

  Future<void> _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    _log.fine('Updating location: ${event.latitude}, ${event.longitude}');

    // Update state with new location
    emit(state.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
    ));

    // Update server
    await updateUserLocation(
      latitude: event.latitude,
      longitude: event.longitude,
      accuracy: event.accuracy,
      heading: event.heading,
      speed: event.speed,
    );
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    _log.info('Searching users: ${event.query}');

    add(LoadNearbyUsers(
      role: state.roleFilter,
      searchQuery: event.query.isNotEmpty ? event.query : null,
      vehicleFilters: state.vehicleFilters.isNotEmpty ? state.vehicleFilters : null,
    ));
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<DiscoveryState> emit,
  ) async {
    _log.info('Applying vehicle filters: ${event.vehicleCategories}');

    add(LoadNearbyUsers(
      role: state.roleFilter,
      searchQuery: state.searchQuery,
      vehicleFilters: event.vehicleCategories,
    ));
  }

  void _onSubscribeToUpdates(
    SubscribeToUpdates event,
    Emitter<DiscoveryState> emit,
  ) {
    if (state.latitude == null || state.longitude == null) {
      return;
    }

    _log.info('Subscribing to realtime updates');

    final params = NearbyUsersParams(
      latitude: state.latitude!,
      longitude: state.longitude!,
      radiusKm: defaultRadius,
      role: state.roleFilter,
      vehicleCategories: state.vehicleFilters.isNotEmpty ? state.vehicleFilters : null,
    );

    _nearbyUsersSubscription?.cancel();
    _nearbyUsersSubscription = getNearbyUsers.watch(params).listen(
      (result) {
        result.fold(
          (failure) => _log.warning('Realtime update failed: ${failure.message}'),
          (users) => add(NearbyUsersUpdated(users)),
        );
      },
      onError: (error) {
        _log.severe('Realtime subscription error', error);
      },
    );
  }

  void _onUnsubscribeFromUpdates(
    UnsubscribeFromUpdates event,
    Emitter<DiscoveryState> emit,
  ) {
    _log.info('Unsubscribing from realtime updates');
    _nearbyUsersSubscription?.cancel();
    _nearbyUsersSubscription = null;
  }

  void _onNearbyUsersUpdated(
    NearbyUsersUpdated event,
    Emitter<DiscoveryState> emit,
  ) {
    _log.fine('Received realtime update: ${event.users.length} users');
    emit(DiscoveryLoaded(
      users: event.users.cast<NearbyUser>(),
      isOnline: state.isOnline,
      hasMore: state.hasMore,
      currentPage: state.currentPage,
      roleFilter: state.roleFilter,
      vehicleFilters: state.vehicleFilters,
      searchQuery: state.searchQuery,
      latitude: state.latitude,
      longitude: state.longitude,
    ));
  }

  Future<void> _onRefreshNearbyUsers(
    RefreshNearbyUsers event,
    Emitter<DiscoveryState> emit,
  ) async {
    add(LoadNearbyUsers(
      role: state.roleFilter,
      searchQuery: state.searchQuery,
      vehicleFilters: state.vehicleFilters.isNotEmpty ? state.vehicleFilters : null,
      forceRefresh: true,
    ));
  }
}
