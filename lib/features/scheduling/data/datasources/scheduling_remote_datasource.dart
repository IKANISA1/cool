import 'dart:async';

import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/scheduled_trip.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../models/scheduled_trip_model.dart';

/// Remote data source for scheduling operations using Supabase
abstract class SchedulingRemoteDataSource {
  /// Create a new scheduled trip
  Future<ScheduledTripModel> createTrip(ScheduledTripParams params);

  /// Update an existing trip
  Future<ScheduledTripModel> updateTrip(String tripId, ScheduledTripParams params);

  /// Delete a trip
  Future<void> deleteTrip(String tripId);

  /// Get a single trip by ID
  Future<ScheduledTripModel> getTrip(String tripId);

  /// Get all trips for current user
  Future<List<ScheduledTripModel>> getMyTrips();

  /// Search trips with filters
  Future<List<ScheduledTripModel>> searchTrips(SearchTripsParams params);

  /// Get upcoming trips
  Future<List<ScheduledTripModel>> getUpcomingTrips({
    TripType? tripType,
    int limit = 20,
  });

  /// Watch a specific trip
  Stream<ScheduledTripModel> watchTrip(String tripId);

  /// Watch nearby trips
  Stream<List<ScheduledTripModel>> watchNearbyTrips(SearchTripsParams params);
}

/// Implementation of SchedulingRemoteDataSource using Supabase
class SchedulingRemoteDataSourceImpl implements SchedulingRemoteDataSource {
  final SupabaseClient _client;
  final _log = Logger('SchedulingRemoteDataSource');

  SchedulingRemoteDataSourceImpl(this._client);

  String? get _currentUserId => _client.auth.currentUser?.id;

  @override
  Future<ScheduledTripModel> createTrip(ScheduledTripParams params) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Creating scheduled trip: ${params.tripType}');

    final data = {
      'user_id': userId,
      'trip_type': params.tripType == TripType.offer ? 'offer' : 'request',
      'when_datetime': params.whenDateTime.toIso8601String(),
      'from_text': params.fromText,
      'to_text': params.toText,
      'seats_qty': params.seatsQty,
      'vehicle_pref': params.vehiclePref,
      'notes': params.notes,
    };

    // Add geo points if present
    if (params.fromGeo != null) {
      data['from_geo'] = 'POINT(${params.fromGeo!.$2} ${params.fromGeo!.$1})';
    }
    if (params.toGeo != null) {
      data['to_geo'] = 'POINT(${params.toGeo!.$2} ${params.toGeo!.$1})';
    }

    final response = await _client
        .from('scheduled_trips')
        .insert(data)
        .select('*, profiles!user_id(*)')
        .single();

    return ScheduledTripModel.fromSupabaseRow(response);
  }

  @override
  Future<ScheduledTripModel> updateTrip(
    String tripId,
    ScheduledTripParams params,
  ) async {
    _log.info('Updating scheduled trip: $tripId');

    final data = {
      'trip_type': params.tripType == TripType.offer ? 'offer' : 'request',
      'when_datetime': params.whenDateTime.toIso8601String(),
      'from_text': params.fromText,
      'to_text': params.toText,
      'seats_qty': params.seatsQty,
      'vehicle_pref': params.vehiclePref,
      'notes': params.notes,
    };

    if (params.fromGeo != null) {
      data['from_geo'] = 'POINT(${params.fromGeo!.$2} ${params.fromGeo!.$1})';
    }
    if (params.toGeo != null) {
      data['to_geo'] = 'POINT(${params.toGeo!.$2} ${params.toGeo!.$1})';
    }

    final response = await _client
        .from('scheduled_trips')
        .update(data)
        .eq('id', tripId)
        .select('*, profiles!user_id(*)')
        .single();

    return ScheduledTripModel.fromSupabaseRow(response);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    _log.info('Deleting scheduled trip: $tripId');

    await _client.from('scheduled_trips').delete().eq('id', tripId);
  }

  @override
  Future<ScheduledTripModel> getTrip(String tripId) async {
    _log.info('Getting scheduled trip: $tripId');

    final response = await _client
        .from('scheduled_trips')
        .select('*, profiles!user_id(*)')
        .eq('id', tripId)
        .single();

    return ScheduledTripModel.fromSupabaseRow(response);
  }

  @override
  Future<List<ScheduledTripModel>> getMyTrips() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    _log.info('Getting my scheduled trips');

    final response = await _client
        .from('scheduled_trips')
        .select('*, profiles!user_id(*)')
        .eq('user_id', userId)
        .order('when_datetime', ascending: true);

    return (response as List)
        .map((row) => ScheduledTripModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduledTripModel>> searchTrips(SearchTripsParams params) async {
    _log.info('Searching scheduled trips');

    // Build base query
    final baseQuery = _client
        .from('scheduled_trips')
        .select('*, profiles!user_id(*)');

    // Apply filters and execute
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = baseQuery;
    
    if (params.tripType != null) {
      query = query.eq(
        'trip_type',
        params.tripType == TripType.offer ? 'offer' : 'request',
      );
    }

    if (params.fromDate != null) {
      query = query.gte('when_datetime', params.fromDate!.toIso8601String());
    }

    if (params.toDate != null) {
      query = query.lte('when_datetime', params.toDate!.toIso8601String());
    }

    if (params.vehiclePref != null) {
      query = query.eq('vehicle_pref', params.vehiclePref!);
    }

    if (params.excludeUserId != null) {
      query = query.neq('user_id', params.excludeUserId!);
    }

    // Only active trips and apply pagination
    final offset = (params.page - 1) * params.pageSize;
    final response = await query
        .eq('is_active', true)
        .order('when_datetime', ascending: true)
        .range(offset, offset + params.pageSize - 1);

    return (response as List)
        .map((row) => ScheduledTripModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduledTripModel>> getUpcomingTrips({
    TripType? tripType,
    int limit = 20,
  }) async {
    _log.info('Getting upcoming trips');

    var query = _client
        .from('scheduled_trips')
        .select('*, profiles!user_id(*)')
        .eq('is_active', true)
        .gte('when_datetime', DateTime.now().toIso8601String());

    if (tripType != null) {
      query = query.eq(
        'trip_type',
        tripType == TripType.offer ? 'offer' : 'request',
      );
    }

    final response = await query
        .order('when_datetime', ascending: true)
        .limit(limit);

    return (response as List)
        .map((row) => ScheduledTripModel.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<ScheduledTripModel> watchTrip(String tripId) {
    _log.info('Watching trip: $tripId');

    final controller = StreamController<ScheduledTripModel>();

    // Initial fetch
    getTrip(tripId).then((trip) {
      if (!controller.isClosed) {
        controller.add(trip);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to changes
    final channel = _client
        .channel('trip_$tripId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scheduled_trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tripId,
          ),
          callback: (payload) {
            getTrip(tripId).then((trip) {
              if (!controller.isClosed) {
                controller.add(trip);
              }
            });
          },
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  @override
  Stream<List<ScheduledTripModel>> watchNearbyTrips(SearchTripsParams params) {
    _log.info('Watching nearby trips');

    final controller = StreamController<List<ScheduledTripModel>>();

    // Initial fetch
    searchTrips(params).then((trips) {
      if (!controller.isClosed) {
        controller.add(trips);
      }
    }).catchError((error) {
      if (!controller.isClosed) {
        controller.addError(error);
      }
    });

    // Subscribe to all trip changes
    final channel = _client
        .channel('scheduled_trips_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scheduled_trips',
          callback: (payload) {
            searchTrips(params).then((trips) {
              if (!controller.isClosed) {
                controller.add(trips);
              }
            });
          },
        )
        .subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }
}
