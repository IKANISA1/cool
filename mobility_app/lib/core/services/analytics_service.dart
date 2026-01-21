import 'dart:async';

import 'package:logging/logging.dart';

/// Analytics service for tracking AI features and app usage
///
/// Provides:
/// - AI request tracking (success/failure, latency)
/// - Feature usage metrics
/// - Session analytics
/// - Export/reporting capabilities
class AnalyticsService {
  static final _log = Logger('AnalyticsService');
  static AnalyticsService? _instance;

  AnalyticsService._();

  /// Singleton instance
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  // =========================================================================
  // AI METRICS
  // =========================================================================

  // AI request counters
  int _aiTotalRequests = 0;
  int _aiSuccessfulRequests = 0;
  int _aiFailedRequests = 0;
  int _aiFallbackUsed = 0;
  int _aiCacheHits = 0;

  // AI latency tracking (last 100 requests)
  final List<int> _aiLatencies = [];
  static const int _maxLatencyHistory = 100;

  // AI feature usage
  final Map<String, int> _aiFeatureUsage = {};

  /// Log an AI request event
  void logAiRequest({
    required String feature,
    required bool success,
    required int latencyMs,
    bool usedFallback = false,
    bool cacheHit = false,
    Map<String, dynamic>? metadata,
  }) {
    _aiTotalRequests++;

    if (success) {
      _aiSuccessfulRequests++;
    } else {
      _aiFailedRequests++;
    }

    if (usedFallback) {
      _aiFallbackUsed++;
    }

    if (cacheHit) {
      _aiCacheHits++;
    }

    // Track latency
    _aiLatencies.add(latencyMs);
    if (_aiLatencies.length > _maxLatencyHistory) {
      _aiLatencies.removeAt(0);
    }

    // Track feature usage
    _aiFeatureUsage[feature] = (_aiFeatureUsage[feature] ?? 0) + 1;

    _log.info(
      '[Analytics] AI ${success ? 'SUCCESS' : 'FAILED'}: $feature '
      '(${latencyMs}ms${usedFallback ? ', fallback' : ''}${cacheHit ? ', cached' : ''})',
    );

    // Fire event to listeners
    _eventController.add(AnalyticsEvent(
      type: AnalyticsEventType.aiRequest,
      feature: feature,
      success: success,
      latencyMs: latencyMs,
      metadata: metadata,
    ));
  }

  /// Log trip scheduling event
  void logTripSchedule({
    required String inputType, // 'text' or 'voice'
    required bool success,
    required int confidence,
    String? vehicleType,
    String? origin,
    String? destination,
  }) {
    logAiRequest(
      feature: 'trip_schedule_$inputType',
      success: success,
      latencyMs: 0, // Tracked separately
      metadata: {
        'input_type': inputType,
        'confidence': confidence,
        'vehicle_type': vehicleType,
        'has_origin': origin != null,
        'has_destination': destination != null,
      },
    );
  }

  /// Log fare estimation event
  void logFareEstimate({
    required bool success,
    required int latencyMs,
    required bool usedFallback,
    double? distanceKm,
    String? vehicleType,
  }) {
    logAiRequest(
      feature: 'fare_estimate',
      success: success,
      latencyMs: latencyMs,
      usedFallback: usedFallback,
      metadata: {
        'distance_km': distanceKm,
        'vehicle_type': vehicleType,
      },
    );
  }

  /// Log driver recommendation event
  void logDriverRecommendation({
    required bool success,
    required int latencyMs,
    required int driversEvaluated,
    required int recommendationsReturned,
  }) {
    logAiRequest(
      feature: 'driver_recommendation',
      success: success,
      latencyMs: latencyMs,
      metadata: {
        'drivers_evaluated': driversEvaluated,
        'recommendations_returned': recommendationsReturned,
      },
    );
  }

  /// Log chat interaction
  void logChatInteraction({
    required bool success,
    required int latencyMs,
    int? messageLength,
    int? responseLength,
  }) {
    logAiRequest(
      feature: 'chat',
      success: success,
      latencyMs: latencyMs,
      metadata: {
        'message_length': messageLength,
        'response_length': responseLength,
      },
    );
  }

  // =========================================================================
  // LOCATION METRICS
  // =========================================================================

  int _locationUpdates = 0;
  int _stationaryUpdates = 0;
  int _movingUpdates = 0;

  /// Log location update for battery optimization tracking
  void logLocationUpdate({
    required bool isStationary,
    double? speedMs,
  }) {
    _locationUpdates++;
    if (isStationary) {
      _stationaryUpdates++;
    } else {
      _movingUpdates++;
    }

    _log.fine(
      '[Analytics] Location: ${isStationary ? 'STATIONARY' : 'MOVING'} '
      '(${speedMs?.toStringAsFixed(2) ?? 'unknown'} m/s)',
    );
  }

  // =========================================================================
  // STATISTICS & REPORTING
  // =========================================================================

  /// Get AI usage statistics
  Map<String, dynamic> getAiStats() {
    final avgLatency = _aiLatencies.isEmpty
        ? 0
        : _aiLatencies.reduce((a, b) => a + b) ~/ _aiLatencies.length;

    final p95Index = (_aiLatencies.length * 0.95).floor();
    final sortedLatencies = List<int>.from(_aiLatencies)..sort();
    final p95Latency = _aiLatencies.isEmpty
        ? 0
        : sortedLatencies[p95Index.clamp(0, sortedLatencies.length - 1)];

    return {
      'totalRequests': _aiTotalRequests,
      'successfulRequests': _aiSuccessfulRequests,
      'failedRequests': _aiFailedRequests,
      'successRate': _aiTotalRequests > 0
          ? (_aiSuccessfulRequests / _aiTotalRequests * 100).toStringAsFixed(1)
          : '0.0',
      'fallbackUsed': _aiFallbackUsed,
      'fallbackRate': _aiTotalRequests > 0
          ? (_aiFallbackUsed / _aiTotalRequests * 100).toStringAsFixed(1)
          : '0.0',
      'cacheHits': _aiCacheHits,
      'cacheHitRate': _aiTotalRequests > 0
          ? (_aiCacheHits / _aiTotalRequests * 100).toStringAsFixed(1)
          : '0.0',
      'avgLatencyMs': avgLatency,
      'p95LatencyMs': p95Latency,
      'featureUsage': Map<String, int>.from(_aiFeatureUsage),
    };
  }

  /// Get location tracking statistics
  Map<String, dynamic> getLocationStats() {
    return {
      'totalUpdates': _locationUpdates,
      'stationaryUpdates': _stationaryUpdates,
      'movingUpdates': _movingUpdates,
      'stationaryRatio': _locationUpdates > 0
          ? (_stationaryUpdates / _locationUpdates * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Get combined statistics for all metrics
  Map<String, dynamic> getAllStats() {
    return {
      'ai': getAiStats(),
      'location': getLocationStats(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Reset all statistics
  void resetStats() {
    _aiTotalRequests = 0;
    _aiSuccessfulRequests = 0;
    _aiFailedRequests = 0;
    _aiFallbackUsed = 0;
    _aiCacheHits = 0;
    _aiLatencies.clear();
    _aiFeatureUsage.clear();
    _locationUpdates = 0;
    _stationaryUpdates = 0;
    _movingUpdates = 0;
    _log.info('[Analytics] Stats reset');
  }

  // =========================================================================
  // EVENT STREAM
  // =========================================================================

  final _eventController = StreamController<AnalyticsEvent>.broadcast();

  /// Stream of analytics events for real-time monitoring
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;

  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// Analytics event types
enum AnalyticsEventType {
  aiRequest,
  locationUpdate,
  userAction,
  error,
}

/// Analytics event data class
class AnalyticsEvent {
  final AnalyticsEventType type;
  final String feature;
  final bool success;
  final int latencyMs;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.type,
    required this.feature,
    required this.success,
    required this.latencyMs,
    this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'feature': feature,
        'success': success,
        'latencyMs': latencyMs,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };
}
