import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ride_request_model.dart';

/// Remote data source for ride request operations using Supabase
abstract class RequestRemoteDataSource {
  /// Send a ride request
  Future<RideRequestModel> sendRequest({
    required String toUserId,
    Map<String, dynamic>? payload,
  });

  /// Accept a ride request
  Future<RideRequestModel> acceptRequest(String requestId);

  /// Deny a ride request
  Future<RideRequestModel> denyRequest(String requestId);

  /// Cancel a pending request
  Future<void> cancelRequest(String requestId);

  /// Get incoming requests for the current user
  Future<List<RideRequestModel>> getIncomingRequests();

  /// Get outgoing requests from the current user
  Future<List<RideRequestModel>> getOutgoingRequests();

  /// Get a single request by ID
  Future<RideRequestModel> getRequest(String requestId);

  /// Subscribe to realtime updates for incoming requests
  Stream<RideRequestModel> watchIncomingRequests();

  /// Subscribe to realtime updates for a specific request
  Stream<RideRequestModel> watchRequest(String requestId);
}

/// Implementation of RequestRemoteDataSource using Supabase
class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  final SupabaseClient _client;
  final _log = Logger('RequestRemoteDataSource');

  RequestRemoteDataSourceImpl(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<RideRequestModel> sendRequest({
    required String toUserId,
    Map<String, dynamic>? payload,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Sending request to user: $toUserId');

    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(seconds: 60));

      final response = await _client.from('ride_requests').insert({
        'from_user': userId,
        'to_user': toUserId,
        'payload': payload ?? {},
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      }).select().single();

      _log.info('Request sent successfully: ${response['id']}');
      return RideRequestModel.fromSupabaseRow(response);
    } catch (e, stackTrace) {
      _log.severe('Failed to send request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<RideRequestModel> acceptRequest(String requestId) async {
    _log.info('Accepting request: $requestId');

    try {
      final response = await _client
          .from('ride_requests')
          .update({
            'status': 'accepted',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return RideRequestModel.fromSupabaseRow(response);
    } catch (e, stackTrace) {
      _log.severe('Failed to accept request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<RideRequestModel> denyRequest(String requestId) async {
    _log.info('Denying request: $requestId');

    try {
      final response = await _client
          .from('ride_requests')
          .update({
            'status': 'denied',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select()
          .single();

      return RideRequestModel.fromSupabaseRow(response);
    } catch (e, stackTrace) {
      _log.severe('Failed to deny request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Cancelling request: $requestId');

    try {
      await _client
          .from('ride_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId)
          .eq('from_user', userId)
          .eq('status', 'pending');
    } catch (e, stackTrace) {
      _log.severe('Failed to cancel request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<RideRequestModel>> getIncomingRequests() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Fetching incoming requests');

    try {
      final response = await _client
          .from('ride_requests')
          .select('''
            *,
            from_profile:profiles!from_user(id, name, avatar_url, rating)
          ''')
          .eq('to_user', userId)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((row) => RideRequestModel.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch incoming requests', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<RideRequestModel>> getOutgoingRequests() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Fetching outgoing requests');

    try {
      final response = await _client
          .from('ride_requests')
          .select('''
            *,
            to_profile:profiles!to_user(id, name, avatar_url, rating)
          ''')
          .eq('from_user', userId)
          .inFilter('status', ['pending', 'accepted'])
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((row) => RideRequestModel.fromSupabaseRow(row as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch outgoing requests', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<RideRequestModel> getRequest(String requestId) async {
    _log.info('Fetching request: $requestId');

    try {
      final response = await _client
          .from('ride_requests')
          .select('''
            *,
            from_profile:profiles!from_user(id, name, avatar_url, rating, phone:users(phone)),
            to_profile:profiles!to_user(id, name, avatar_url, rating, phone:users(phone))
          ''')
          .eq('id', requestId)
          .single();

      return RideRequestModel.fromSupabaseRow(response);
    } catch (e, stackTrace) {
      _log.severe('Failed to fetch request', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<RideRequestModel> watchIncomingRequests() {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Setting up realtime subscription for incoming requests');

    final controller = StreamController<RideRequestModel>();

    final channel = _client
        .channel('incoming_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_user',
            value: userId,
          ),
          callback: (payload) {
            _log.fine('New incoming request received');
            final request = RideRequestModel.fromSupabaseRow(
              payload.newRecord,
            );
            if (!controller.isClosed) {
              controller.add(request);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _log.info('Closing incoming requests subscription');
      channel.unsubscribe();
    };

    return controller.stream;
  }

  @override
  Stream<RideRequestModel> watchRequest(String requestId) {
    _log.info('Setting up realtime subscription for request: $requestId');

    final controller = StreamController<RideRequestModel>();

    final channel = _client
        .channel('request_$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (payload) {
            _log.fine('Request updated: $requestId');
            final request = RideRequestModel.fromSupabaseRow(
              payload.newRecord,
            );
            if (!controller.isClosed) {
              controller.add(request);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _log.info('Closing request subscription: $requestId');
      channel.unsubscribe();
    };

    return controller.stream;
  }
}
