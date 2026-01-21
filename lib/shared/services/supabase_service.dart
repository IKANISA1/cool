// ============================================================================
// SUPABASE SERVICE - shared/services/supabase_service.dart
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ridelink/shared/services/gemini_service.dart';

class SupabaseService {
  late final SupabaseClient _client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  SupabaseService() {
    _client = Supabase.instance.client;
  }


  // Real-time Presence
  RealtimeChannel createPresenceChannel(String userId) {
    return _client.channel('presence:nearby')
      ..onPresenceSync(
        (payload, [ref]) {
          // Handle presence sync
        },
      )
      ..subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _client.channel('presence:nearby').track({
            'user_id': userId,
            'online_at': DateTime.now().toIso8601String(),
          });
        }
      });
  }

  // Nearby Users Query
  Future<List<Map<String, dynamic>>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String role, // 'driver' or 'passenger'
  }) async {
    final response = await _client.rpc('get_nearby_users', params: {
      'lat': latitude,
      'lng': longitude,
      'radius_km': radiusKm,
      'user_role': role,
    });

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Send Ride Request
  Future<void> sendRideRequest({
    required String fromUserId,
    required String toUserId,
    required Map<String, dynamic> tripData,
  }) async {
    await _client.from('ride_requests').insert({
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'trip_data': tripData,
      'status': 'pending',
      'expires_at': DateTime.now()
          .add(const Duration(minutes: 1))
          .toIso8601String(),
    });
  }

  // Schedule Trip
  Future<void> scheduleTrip({
    required String userId,
    required TripScheduleData tripData,
  }) async {
    await _client.from('scheduled_trips').insert({
      'user_id': userId,
      'origin': tripData.origin,
      'destination': tripData.destination,
      'departure_time': tripData.departureTime.toIso8601String(),
      'seats': tripData.seats,
      'vehicle_preference': tripData.vehiclePreference,
      'status': 'scheduled',
    });
  }
}
