import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/api_constants.dart';
import 'location_service.dart';

/// Service for managing realtime user presence
/// 
/// Handles online/offline status tracking, location updates,
/// and Supabase Realtime presence channel management.
class PresenceService {
  static final _log = Logger('PresenceService');

  final SupabaseClient _client;
  final LocationService _locationService;

  RealtimeChannel? _presenceChannel;
  StreamSubscription<Position>? _locationSubscription;
  String? _currentUserId;
  bool _isTracking = false;

  PresenceService({
    required SupabaseClient client,
    required LocationService locationService,
  })  : _client = client,
        _locationService = locationService;

  /// Check if currently tracking presence
  bool get isTracking => _isTracking;

  /// Get the presence channel for external subscriptions
  RealtimeChannel? get channel => _presenceChannel;

  /// Initialize presence tracking for current user
  Future<void> initializePresence() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _log.warning('Cannot initialize presence: user not authenticated');
      return;
    }

    _currentUserId = userId;

    // Create presence channel
    _presenceChannel = _client.channel('online_users');

    // Subscribe to channel
    _presenceChannel!.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _log.info('Presence channel subscribed');
        _startTracking();
      } else if (error != null) {
        _log.warning('Presence channel error: $error');
      }
    });
  }

  /// Start location tracking and presence updates
  Future<void> _startTracking() async {
    if (_isTracking) return;

    try {
      // Update presence immediately with current location
      await _updatePresence(online: true);

      // Start listening to location updates
      _locationSubscription = _locationService
          .getPositionStream(
            distanceFilter: 50, // Update when moved 50+ meters
          )
          .listen(
            (position) => _updatePresenceWithPosition(position, online: true),
            onError: (error) {
              _log.warning('Location stream error: $error');
            },
          );

      _isTracking = true;
      _log.info('Presence tracking started');
    } catch (e) {
      _log.warning('Failed to start presence tracking: $e');
    }
  }

  /// Update presence with current location
  Future<void> _updatePresence({required bool online}) async {
    if (_currentUserId == null) return;

    try {
      final position = await _locationService.getCurrentPosition();
      await _updatePresenceWithPosition(position, online: online);
    } catch (e) {
      _log.warning('Failed to get location for presence: $e');
      // Update presence without location
      await _updatePresenceWithoutLocation(online: online);
    }
  }

  /// Update presence with given position
  Future<void> _updatePresenceWithPosition(
    Position position, {
    required bool online,
  }) async {
    if (_currentUserId == null || _presenceChannel == null) return;

    try {
      // Track in realtime channel
      await _presenceChannel!.track({
        'user_id': _currentUserId,
        'online_at': DateTime.now().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

      // Also persist to database
      await _client.from(ApiConstants.presenceTable).upsert({
        'user_id': _currentUserId,
        'is_online': online,
        'last_seen_at': DateTime.now().toIso8601String(),
        'last_lat': position.latitude,
        'last_lng': position.longitude,
        'accuracy_m': position.accuracy,
        'updated_at': DateTime.now().toIso8601String(),
      });

      _log.fine('Presence updated: lat=${position.latitude}, lng=${position.longitude}');
    } catch (e) {
      _log.warning('Failed to update presence: $e');
    }
  }

  /// Update presence without location (fallback)
  Future<void> _updatePresenceWithoutLocation({required bool online}) async {
    if (_currentUserId == null) return;

    try {
      await _client.from(ApiConstants.presenceTable).upsert({
        'user_id': _currentUserId,
        'is_online': online,
        'last_seen_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _log.warning('Failed to update presence without location: $e');
    }
  }

  /// Set user online
  Future<void> goOnline() async {
    if (!_isTracking) {
      await _startTracking();
    }
    await _updatePresence(online: true);
  }

  /// Set user offline
  Future<void> goOffline() async {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;

    if (_currentUserId == null) return;

    try {
      // Untrack from realtime channel
      await _presenceChannel?.untrack();

      // Update database
      await _client.from(ApiConstants.presenceTable).update({
        'is_online': false,
        'last_seen_at': DateTime.now().toIso8601String(),
      }).eq('user_id', _currentUserId!);

      _log.info('User set offline');
    } catch (e) {
      _log.warning('Failed to set offline: $e');
    }
  }

  /// Get count of online users from the channel
  int getOnlineUserCount() {
    if (_presenceChannel == null) return 0;
    return _presenceChannel!.presenceState().length;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _isTracking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    if (_presenceChannel != null) {
      await _presenceChannel!.unsubscribe();
      _presenceChannel = null;
    }

    _currentUserId = null;
    _log.info('Presence service disposed');
  }
}
