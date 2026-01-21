import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/discovery_repository.dart';
import '../models/nearby_user_model.dart';

/// Remote data source for discovery operations using Supabase
///
/// Handles:
/// - Calling the `nearby_users` database function
/// - Real-time subscriptions to presence updates
/// - Online status management
/// - Location updates
abstract class DiscoveryRemoteDataSource {
  /// Fetch nearby users from the database
  Future<List<NearbyUserModel>> getNearbyUsers(NearbyUsersParams params);

  /// Subscribe to realtime presence updates
  Stream<List<NearbyUserModel>> watchNearbyUsers(NearbyUsersParams params);

  /// Set user online/offline status
  Future<bool> setOnlineStatus(bool isOnline);

  /// Update user's current location
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  });

  /// Get current online status
  Future<bool> getOnlineStatus();

  /// Search users by name
  Future<List<NearbyUserModel>> searchUsers(String query);
}

/// Implementation of DiscoveryRemoteDataSource using Supabase
class DiscoveryRemoteDataSourceImpl implements DiscoveryRemoteDataSource {
  final SupabaseClient _client;
  final _log = Logger('DiscoveryRemoteDataSource');

  DiscoveryRemoteDataSourceImpl(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<NearbyUserModel>> getNearbyUsers(NearbyUsersParams params) async {
    _log.info('Fetching nearby users: lat=${params.latitude}, lng=${params.longitude}');

    try {
      // Call the nearby_users database function
      final response = await _client.rpc(
        'nearby_users',
        params: {
          'user_lat': params.latitude,
          'user_lng': params.longitude,
          'radius_km': params.radiusKm,
          'user_role': params.role,
          'exclude_user_id': params.excludeUserId ?? _currentUserId,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      _log.info('Found ${data.length} nearby users');

      List<NearbyUserModel> users = data
          .map((row) => NearbyUserModel.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();

      // Apply vehicle category filter if specified
      if (params.vehicleCategories != null && params.vehicleCategories!.isNotEmpty) {
        users = users.where((user) {
          if (user.vehicleCategory == null) return false;
          return params.vehicleCategories!.contains(user.vehicleCategory!.toLowerCase());
        }).toList();
      }

      // Apply pagination
      final startIndex = (params.page - 1) * params.pageSize;
      final endIndex = startIndex + params.pageSize;
      
      if (startIndex >= users.length) {
        return [];
      }
      
      return users.sublist(
        startIndex,
        endIndex > users.length ? users.length : endIndex,
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch nearby users', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<NearbyUserModel>> watchNearbyUsers(NearbyUsersParams params) {
    _log.info('Setting up realtime subscription for nearby users');

    // Create a controller to manage the stream
    final controller = StreamController<List<NearbyUserModel>>();

    // Initial fetch
    getNearbyUsers(params).then((users) {
      if (!controller.isClosed) {
        controller.add(users);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to presence table changes
    final channel = _client
        .channel('presence_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'presence',
          callback: (payload) {
            _log.fine('Presence change detected: ${payload.eventType}');
            // Refetch nearby users when presence changes
            getNearbyUsers(params).then((users) {
              if (!controller.isClosed) {
                controller.add(users);
              }
            }).catchError((error) {
              if (!controller.isClosed) {
                controller.addError(error);
              }
            });
          },
        )
        .subscribe();

    // Clean up on stream close
    controller.onCancel = () {
      _log.info('Closing nearby users subscription');
      channel.unsubscribe();
    };

    return controller.stream;
  }

  @override
  Future<bool> setOnlineStatus(bool isOnline) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Setting online status to $isOnline');

    try {
      await _client.from('presence').upsert({
        'user_id': userId,
        'is_online': isOnline,
        'last_seen_at': DateTime.now().toIso8601String(),
      });

      return isOnline;
    } catch (e, stackTrace) {
      _log.severe('Failed to set online status', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.fine('Updating location: lat=$latitude, lng=$longitude');

    try {
      await _client.from('presence').upsert({
        'user_id': userId,
        'last_lat': latitude,
        'last_lng': longitude,
        'accuracy_m': accuracy,
        'heading': heading,
        'speed': speed,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stackTrace) {
      _log.severe('Failed to update location', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> getOnlineStatus() async {
    final userId = _currentUserId;
    if (userId == null) {
      return false;
    }

    try {
      final response = await _client
          .from('presence')
          .select('is_online')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['is_online'] as bool? ?? false;
    } catch (e, stackTrace) {
      _log.severe('Failed to get online status', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<NearbyUserModel>> searchUsers(String query) async {
    _log.info('Searching users with query: $query');

    try {
      final response = await _client
          .from('profiles')
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      final List<dynamic> data = response as List<dynamic>;
      
      return data
          .map((row) => NearbyUserModel.fromProfileRow(row as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Failed to search users', e, stackTrace);
      rethrow;
    }
  }
}
