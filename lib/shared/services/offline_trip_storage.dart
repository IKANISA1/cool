import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

/// Offline-first storage for scheduled trips using Hive
///
/// Provides local caching of scheduled trips for offline access
/// and faster loading on app startup.
class OfflineTripStorage {
  static final _log = Logger('OfflineTripStorage');
  static const _boxName = 'scheduled_trips_cache';
  static const _tripsKey = 'trips';
  static const _lastSyncKey = 'last_sync';

  Box? _box;

  /// Initialize Hive and open the trips box
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      _log.info('Offline trip storage initialized');
    } catch (e) {
      _log.warning('Failed to initialize offline storage: $e');
    }
  }

  /// Cache a list of scheduled trips locally
  Future<void> cacheTrips(List<Map<String, dynamic>> trips) async {
    if (_box == null) {
      _log.warning('Storage not initialized, cannot cache trips');
      return;
    }

    try {
      final jsonString = jsonEncode(trips);
      await _box!.put(_tripsKey, jsonString);
      await _box!.put(_lastSyncKey, DateTime.now().toIso8601String());
      _log.info('Cached ${trips.length} trips offline');
    } catch (e) {
      _log.warning('Failed to cache trips: $e');
    }
  }

  /// Get cached trips from local storage
  Future<List<Map<String, dynamic>>> getCachedTrips() async {
    if (_box == null) {
      _log.warning('Storage not initialized, returning empty list');
      return [];
    }

    try {
      final jsonString = _box!.get(_tripsKey, defaultValue: '[]') as String;
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _log.warning('Failed to get cached trips: $e');
      return [];
    }
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSync() async {
    if (_box == null) return null;

    try {
      final isoString = _box!.get(_lastSyncKey) as String?;
      if (isoString == null) return null;
      return DateTime.parse(isoString);
    } catch (e) {
      _log.warning('Failed to get last sync time: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than given duration)
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all cached trips
  Future<void> clearCache() async {
    if (_box == null) return;

    try {
      await _box!.delete(_tripsKey);
      await _box!.delete(_lastSyncKey);
      _log.info('Offline trip cache cleared');
    } catch (e) {
      _log.warning('Failed to clear cache: $e');
    }
  }

  /// Close the storage box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
