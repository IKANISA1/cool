import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/station_models.dart';

/// Remote data source for station locator using Supabase
class StationRemoteDataSource {
  final SupabaseClient _client;

  StationRemoteDataSource(this._client);

  /// Get nearby battery swap stations using RPC function
  Future<List<BatterySwapStationModel>> getNearbyBatterySwapStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
  }) async {
    final response = await _client.rpc(
      'nearby_battery_swap_stations',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusKm,
        'limit_count': limit,
      },
    );

    final data = response as List<dynamic>;
    return data
        .map((json) => BatterySwapStationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get nearby EV charging stations using RPC function
  Future<List<EVChargingStationModel>> getNearbyEVChargingStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? connectorFilter,
    double? minPowerKw,
    int limit = 20,
  }) async {
    final response = await _client.rpc(
      'nearby_ev_charging_stations',
      params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusKm,
        'connector_filter': connectorFilter,
        'min_power_kw': minPowerKw,
        'limit_count': limit,
      },
    );

    final data = response as List<dynamic>;
    return data
        .map((json) => EVChargingStationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get reviews for a station
  Future<List<StationReviewModel>> getStationReviews({
    required String stationType,
    required String stationId,
    int limit = 20,
  }) async {
    final response = await _client
        .from('station_reviews')
        .select()
        .eq('station_type', stationType)
        .eq('station_id', stationId)
        .order('created_at', ascending: false)
        .limit(limit);

    final data = response as List<dynamic>;
    return data
        .map((json) => StationReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Submit a review
  Future<StationReviewModel> submitReview({
    required String stationType,
    required String stationId,
    required int rating,
    String? comment,
    int? serviceQuality,
    int? waitTimeMinutes,
    int? priceRating,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('station_reviews')
        .insert({
          'user_id': userId,
          'station_type': stationType,
          'station_id': stationId,
          'rating': rating,
          'comment': comment,
          'service_quality': serviceQuality,
          'wait_time_minutes': waitTimeMinutes,
          'price_rating': priceRating,
        })
        .select()
        .single();

    return StationReviewModel.fromJson(response);
  }

  /// Add station to favorites
  Future<void> addToFavorites({
    required String stationType,
    required String stationId,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client.from('station_favorites').upsert({
      'user_id': userId,
      'station_type': stationType,
      'station_id': stationId,
      'notes': notes,
    });
  }

  /// Remove station from favorites
  Future<void> removeFromFavorites({
    required String stationType,
    required String stationId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('station_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('station_type', stationType)
        .eq('station_id', stationId);
  }

  /// Get user's favorite station IDs
  Future<List<String>> getFavoriteStationIds({
    required String stationType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }

    final response = await _client
        .from('station_favorites')
        .select('station_id')
        .eq('user_id', userId)
        .eq('station_type', stationType);

    final data = response as List<dynamic>;
    return data.map((row) => row['station_id'] as String).toList();
  }

  /// Report station availability
  Future<void> reportAvailability({
    required String stationType,
    required String stationId,
    int? batteriesAvailable,
    int? portsAvailable,
    bool? isOperational,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;

    await _client.from('station_availability_reports').insert({
      'user_id': userId,
      'station_type': stationType,
      'station_id': stationId,
      'batteries_available': batteriesAvailable,
      'ports_available': portsAvailable,
      'is_operational': isOperational,
      'notes': notes,
    });
  }

  /// Fetch stations from Google Places API via Edge Function
  Future<int> fetchStationsFromGoogle({
    required double latitude,
    required double longitude,
    required String stationType,
    int radiusMeters = 10000,
  }) async {
    final response = await _client.functions.invoke(
      'fetch-charging-stations',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMeters,
        'stationType': stationType,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to fetch stations: ${response.data}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }
}
