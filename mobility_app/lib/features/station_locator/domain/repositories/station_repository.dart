import 'package:dartz/dartz.dart';

import '../entities/battery_swap_station.dart';
import '../entities/ev_charging_station.dart';
import '../entities/station_review.dart';

/// Filter options for station search
class StationFilter {
  final double? radiusKm;
  final String? connectorType;
  final double? minPowerKw;
  final bool? hasAvailability;
  final double? minRating;

  const StationFilter({
    this.radiusKm,
    this.connectorType,
    this.minPowerKw,
    this.hasAvailability,
    this.minRating,
  });
}

/// Abstract repository for station locator operations
abstract class StationRepository {
  /// Get nearby battery swap stations
  Future<Either<String, List<BatterySwapStation>>> getNearbyBatterySwapStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
  });

  /// Get nearby EV charging stations
  Future<Either<String, List<EVChargingStation>>> getNearbyEVChargingStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? connectorType,
    double? minPowerKw,
    int limit = 20,
  });

  /// Get station reviews
  Future<Either<String, List<StationReview>>> getStationReviews({
    required String stationType,
    required String stationId,
    int limit = 20,
  });

  /// Submit a station review
  Future<Either<String, StationReview>> submitReview({
    required String stationType,
    required String stationId,
    required int rating,
    String? comment,
    int? serviceQuality,
    int? waitTimeMinutes,
    int? priceRating,
  });

  /// Add station to favorites
  Future<Either<String, void>> addToFavorites({
    required String stationType,
    required String stationId,
    String? notes,
  });

  /// Remove station from favorites
  Future<Either<String, void>> removeFromFavorites({
    required String stationType,
    required String stationId,
  });

  /// Get user's favorite stations
  Future<Either<String, List<String>>> getFavoriteStationIds({
    required String stationType,
  });

  /// Report station availability
  Future<Either<String, void>> reportAvailability({
    required String stationType,
    required String stationId,
    int? batteriesAvailable,
    int? portsAvailable,
    bool? isOperational,
    String? notes,
  });

  /// Fetch stations from Google Places API (admin/refresh)
  Future<Either<String, int>> fetchStationsFromGoogle({
    required double latitude,
    required double longitude,
    required String stationType,
    int radiusMeters = 10000,
  });
}
