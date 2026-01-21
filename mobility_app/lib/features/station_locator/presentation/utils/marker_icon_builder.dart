import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builder for custom map marker icons
///
/// Creates dynamic marker icons based on station type, availability,
/// and operational status with proper caching support.
class MarkerIconBuilder {
  /// Create a custom marker icon for a station
  ///
  /// Color coding:
  /// - Green: 75%+ availability
  /// - Orange: 50-74% availability
  /// - Red: <50% availability
  /// - Grey: Not operational
  static Future<BitmapDescriptor> createCustomMarkerIcon({
    required String stationType,
    required bool isOperational,
    required double availabilityPercent,
    int size = 120,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    // Determine marker color based on availability
    Color markerColor;
    if (!isOperational) {
      markerColor = Colors.grey;
    } else if (availabilityPercent >= 75) {
      markerColor = Colors.green;
    } else if (availabilityPercent >= 50) {
      markerColor = Colors.orange;
    } else {
      markerColor = Colors.red;
    }

    // Draw shadow circle
    paint.color = Colors.black.withOpacity(0.2);
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 4),
      size / 2.5,
      paint,
    );

    // Draw main colored circle
    paint.color = markerColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      paint,
    );

    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3,
      paint,
    );

    // Draw station type icon
    final icon = stationType == 'battery_swap'
        ? Icons.battery_charging_full
        : Icons.ev_station;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size / 3,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: markerColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    // Convert to bitmap
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Create a cluster marker icon showing the count of stations
  static Future<BitmapDescriptor> createClusterIcon({
    required int clusterSize,
    required String stationType,
    int size = 120,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    // Primary color based on station type
    final primaryColor =
        stationType == 'battery_swap' ? Colors.blue : Colors.green;

    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      Offset(size / 2, size / 2 + 4),
      size / 2.2,
      paint,
    );

    // Draw outer colored circle
    paint.color = primaryColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.2,
      paint,
    );

    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      paint,
    );

    // Draw cluster count text
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: clusterSize.toString(),
      style: TextStyle(
        fontSize: size / 3,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    // Convert to bitmap
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}

/// Cache manager for marker icons to improve performance
class MarkerCacheManager {
  static final MarkerCacheManager _instance = MarkerCacheManager._internal();
  factory MarkerCacheManager() => _instance;
  MarkerCacheManager._internal();

  final Map<String, BitmapDescriptor> _cache = {};
  static const int _maxCacheSize = 50;

  /// Get cached icon or create new one
  Future<BitmapDescriptor> getOrCreate(
    String key,
    Future<BitmapDescriptor> Function() creator,
  ) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final icon = await creator();

    // LRU-style cache management
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = icon;
    return icon;
  }

  /// Clear cached icons
  void clear() {
    _cache.clear();
  }

  /// Current cache size
  int get size => _cache.length;
}
