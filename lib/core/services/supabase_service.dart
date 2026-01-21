import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/api_constants.dart';

/// Supabase service wrapper
///
/// Provides convenient methods for common Supabase operations
/// and handles realtime subscriptions.
class SupabaseService {
  static final _log = Logger('SupabaseService');

  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Get the current user
  User? get currentUser => _client.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ═══════════════════════════════════════════════════════════
  // AUTH METHODS
  // ═══════════════════════════════════════════════════════════

  /// Sign in with phone (sends OTP)
  Future<void> signInWithPhone(String phoneNumber) async {
    await _client.auth.signInWithOtp(
      phone: phoneNumber,
    );
    _log.info('OTP sent to $phoneNumber');
  }

  /// Verify OTP
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
    _log.info('OTP verified for $phone');
    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    _log.info('User signed out');
  }

  // ═══════════════════════════════════════════════════════════
  // PRESENCE METHODS
  // ═══════════════════════════════════════════════════════════

  /// Update user presence (online status + location)
  Future<void> updatePresence({
    required double latitude,
    required double longitude,
    double? accuracy,
    bool isOnline = true,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(ApiConstants.presenceTable).upsert({
      'user_id': userId,
      'is_online': isOnline,
      'last_lat': latitude,
      'last_lng': longitude,
      'accuracy_m': accuracy,
      'last_seen_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    _log.fine('Presence updated: online=$isOnline, lat=$latitude, lng=$longitude');
  }

  /// Set user offline
  Future<void> setOffline() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(ApiConstants.presenceTable).update({
      'is_online': false,
      'last_seen_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    _log.info('User set offline');
  }

  // ═══════════════════════════════════════════════════════════
  // DISCOVERY METHODS
  // ═══════════════════════════════════════════════════════════

  /// Find nearby users using PostGIS function
  Future<List<Map<String, dynamic>>> findNearbyUsers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? role,
  }) async {
    final response = await _client.rpc(
      ApiConstants.nearbyUsersFunction,
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusKm,
        if (role != null) 'user_role': role,
      },
    );

    _log.fine('Found ${response.length} nearby users');
    return List<Map<String, dynamic>>.from(response);
  }

  // ═══════════════════════════════════════════════════════════
  // REQUEST METHODS
  // ═══════════════════════════════════════════════════════════

  /// Send a ride request
  Future<Map<String, dynamic>> sendRideRequest({
    required String toUserId,
    required Map<String, dynamic> payload,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final response = await _client
        .from(ApiConstants.rideRequestsTable)
        .insert({
          'from_user': userId,
          'to_user': toUserId,
          'payload': payload,
          'status': ApiConstants.statusPending,
          'expires_at': DateTime.now()
              .add(const Duration(seconds: 60))
              .toIso8601String(),
        })
        .select()
        .single();

    _log.info('Ride request sent to $toUserId');
    return response;
  }

  /// Update request status
  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    await _client.from(ApiConstants.rideRequestsTable).update({
      'status': status,
    }).eq('id', requestId);

    _log.info('Request $requestId updated to $status');
  }

  // ═══════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════

  /// Subscribe to presence updates
  RealtimeChannel subscribeToPresence(
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    final channel = _client.channel(ApiConstants.presenceChannel);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: ApiConstants.presenceTable,
          callback: (payload) {
            _log.fine('Presence update: ${payload.newRecord}');
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to incoming ride requests
  RealtimeChannel subscribeToMyRequests(
    void Function(Map<String, dynamic> payload) onRequest,
  ) {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    final channel = _client.channel(ApiConstants.requestsChannel);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: ApiConstants.rideRequestsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_user',
            value: userId,
          ),
          callback: (payload) {
            _log.info('Incoming request: ${payload.newRecord}');
            onRequest(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }
}
