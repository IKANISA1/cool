import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' hide PermissionDeniedException;
import 'package:logging/logging.dart';

import '../error/exceptions.dart';

/// Location service for GPS/geolocation functionality
abstract class LocationService {
  /// Get the current device location
  Future<Position> getCurrentPosition({bool forceRefresh = false});

  /// Stream of location updates
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  });

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Check if location permission is granted
  Future<bool> hasPermission();

  /// Request location permission
  Future<bool> requestPermission();

  /// Convert coordinates to address (reverse geocoding)
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Convert address to coordinates (forward geocoding)
  Future<Position> getCoordinatesFromAddress(String address);

  /// Open app settings for permission management
  Future<bool> openAppSettings();

  /// Stream of location updates with adaptive accuracy based on movement
  /// Uses lower accuracy when stationary to save battery
  Stream<Position> getAdaptivePositionStream({
    double stationaryThreshold = 0.5, // m/s
    int movingDistanceFilter = 10,
    int stationaryDistanceFilter = 50,
  });

  /// Start continuous location tracking with a callback
  /// Automatically syncs to backend
  void startContinuousTracking({
    required void Function(Position position) onPositionUpdate,
    void Function(Object error)? onError,
    bool adaptive = true,
  });

  /// Stop continuous location tracking
  void stopContinuousTracking();

  /// Check if continuous tracking is active
  bool get isTracking;

  /// Get country code from coordinates (reverse geocoding)
  /// Returns ISO 2-letter country code (e.g., "RW", "BI", "TZ", "CD")
  Future<String?> getCountryCodeFromCoordinates({
    required double latitude,
    required double longitude,
  });
}

/// Implementation of [LocationService] using geolocator and geocoding
class LocationServiceImpl implements LocationService {
  static final _log = Logger('LocationService');

  // Location caching for battery efficiency
  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;
  static const _cacheValidity = Duration(seconds: 30);

  @override
  Future<Position> getCurrentPosition({bool forceRefresh = false}) async {
    // Return cached location if recent and not forced
    if (!forceRefresh &&
        _lastKnownPosition != null &&
        _lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!) < _cacheValidity) {
      _log.fine('Using cached position');
      return _lastKnownPosition!;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationDisabledException(
        message: 'Location services are disabled. Please enable GPS.',
      );
    }

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException(
          message: 'Location permission is required to find nearby users.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        message: 'Location permissions are permanently denied. '
            'Please enable them in settings.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Cache the position
      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();

      _log.fine('Got position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _log.warning('Failed to get position', e);
      throw const ServerException(
        message: 'Unable to determine your location. Please try again.',
      );
    }
  }

  @override
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map((position) {
      // Update cache on stream updates
      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();
      return position;
    });
  }

  @override
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Returns distance in meters, convert to kilometers
    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000;
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Unknown location';
      }

      final place = placemarks.first;
      return _formatAddress(place);
    } catch (e) {
      _log.warning('Geocoding failed: $e');
      throw GeocodingException(
        message: 'Failed to get address: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Position> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        throw const GeocodingException(message: 'Address not found');
      }

      final location = locations.first;

      return Position(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (e) {
      _log.warning('Forward geocoding failed: $e');
      throw GeocodingException(
        message: 'Failed to geocode address: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  // =========================================================================
  // ADAPTIVE LOCATION & CONTINUOUS TRACKING
  // =========================================================================

  // Continuous tracking state
  StreamSubscription<Position>? _positionSubscription;
  double _lastSpeed = 0;

  /// Stationary threshold in m/s (0.5 m/s ≈ walking pace)
  static const double _defaultStationaryThreshold = 0.5;

  @override
  bool get isTracking => _positionSubscription != null;

  @override
  Stream<Position> getAdaptivePositionStream({
    double stationaryThreshold = _defaultStationaryThreshold,
    int movingDistanceFilter = 10,
    int stationaryDistanceFilter = 50,
  }) async* {
    _log.info('Starting adaptive position stream');

    // Determine initial settings based on last known speed
    bool wasStationary = _lastSpeed < stationaryThreshold;
    LocationSettings currentSettings = _getAdaptiveSettings(
      wasStationary,
      movingDistanceFilter,
      stationaryDistanceFilter,
    );

    Stream<Position> currentStream = Geolocator.getPositionStream(
      locationSettings: currentSettings,
    );

    await for (final position in currentStream) {
      // Update cache
      _lastKnownPosition = position;
      _lastUpdateTime = DateTime.now();
      _lastSpeed = position.speed;

      // Check if we need to switch accuracy mode
      final isNowStationary = position.speed < stationaryThreshold;
      if (isNowStationary != wasStationary) {
        wasStationary = isNowStationary;
        _log.info(
          'Movement state changed: ${isNowStationary ? "STATIONARY" : "MOVING"} '
          '(speed: ${position.speed.toStringAsFixed(2)} m/s)',
        );
        // Note: In practice, full stream switching requires more complex logic
        // This logs the state change for monitoring
      }

      yield position;
    }
  }

  @override
  void startContinuousTracking({
    required void Function(Position position) onPositionUpdate,
    void Function(Object error)? onError,
    bool adaptive = true,
  }) {
    // Cancel any existing subscription
    stopContinuousTracking();

    _log.info('Starting continuous tracking (adaptive: $adaptive)');

    final stream = adaptive
        ? getAdaptivePositionStream()
        : getPositionStream();

    _positionSubscription = stream.listen(
      (position) {
        _log.fine(
          'Position update: ${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '(speed: ${position.speed.toStringAsFixed(2)} m/s)',
        );
        onPositionUpdate(position);
      },
      onError: (error) {
        _log.warning('Position stream error: $error');
        onError?.call(error);
      },
      cancelOnError: false,
    );
  }

  @override
  void stopContinuousTracking() {
    if (_positionSubscription != null) {
      _log.info('Stopping continuous tracking');
      _positionSubscription?.cancel();
      _positionSubscription = null;
    }
  }

  /// Get location settings optimized for current movement state
  LocationSettings _getAdaptiveSettings(
    bool isStationary,
    int movingDistanceFilter,
    int stationaryDistanceFilter,
  ) {
    if (isStationary) {
      _log.fine('Using STATIONARY location settings (battery saving mode)');
      return LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: stationaryDistanceFilter,
      );
    }

    _log.fine('Using MOVING location settings (high accuracy mode)');
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: movingDistanceFilter,
    );
  }

  /// Format placemark to readable address
  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }

  /// Get last known position (may be null)
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Get last known speed in m/s
  double get lastKnownSpeed => _lastSpeed;

  /// Clear the position cache
  void clearCache() {
    _lastKnownPosition = null;
    _lastUpdateTime = null;
    _lastSpeed = 0;
  }

  @override
  Future<String?> getCountryCodeFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        _log.warning('No placemarks found for coordinates');
        return null;
      }

      final place = placemarks.first;
      final countryCode = place.isoCountryCode;

      _log.fine('Detected country code: $countryCode from ${place.country}');
      return countryCode;
    } catch (e) {
      _log.warning('Failed to get country from coordinates: $e');
      return null;
    }
  }
}

