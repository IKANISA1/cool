import 'package:dartz/dartz.dart';

import '../../domain/entities/battery_swap_station.dart';
import '../../domain/entities/ev_charging_station.dart';
import '../../domain/entities/station_review.dart';
import '../../domain/repositories/station_repository.dart';
import '../datasources/station_remote_datasource.dart';

/// Implementation of StationRepository using remote data source
class StationRepositoryImpl implements StationRepository {
  final StationRemoteDataSource _remoteDataSource;

  StationRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<String, List<BatterySwapStation>>> getNearbyBatterySwapStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int limit = 20,
  }) async {
    try {
      final stations = await _remoteDataSource.getNearbyBatterySwapStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );
      return Right(stations);
    } catch (e) {
      return Left('Failed to fetch battery swap stations: $e');
    }
  }

  @override
  Future<Either<String, List<EVChargingStation>>> getNearbyEVChargingStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? connectorType,
    double? minPowerKw,
    int limit = 20,
  }) async {
    try {
      final stations = await _remoteDataSource.getNearbyEVChargingStations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        connectorFilter: connectorType,
        minPowerKw: minPowerKw,
        limit: limit,
      );
      return Right(stations);
    } catch (e) {
      return Left('Failed to fetch EV charging stations: $e');
    }
  }

  @override
  Future<Either<String, List<StationReview>>> getStationReviews({
    required String stationType,
    required String stationId,
    int limit = 20,
  }) async {
    try {
      final reviews = await _remoteDataSource.getStationReviews(
        stationType: stationType,
        stationId: stationId,
        limit: limit,
      );
      return Right(reviews);
    } catch (e) {
      return Left('Failed to fetch reviews: $e');
    }
  }

  @override
  Future<Either<String, StationReview>> submitReview({
    required String stationType,
    required String stationId,
    required int rating,
    String? comment,
    int? serviceQuality,
    int? waitTimeMinutes,
    int? priceRating,
  }) async {
    try {
      final review = await _remoteDataSource.submitReview(
        stationType: stationType,
        stationId: stationId,
        rating: rating,
        comment: comment,
        serviceQuality: serviceQuality,
        waitTimeMinutes: waitTimeMinutes,
        priceRating: priceRating,
      );
      return Right(review);
    } catch (e) {
      return Left('Failed to submit review: $e');
    }
  }

  @override
  Future<Either<String, void>> addToFavorites({
    required String stationType,
    required String stationId,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.addToFavorites(
        stationType: stationType,
        stationId: stationId,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left('Failed to add to favorites: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromFavorites({
    required String stationType,
    required String stationId,
  }) async {
    try {
      await _remoteDataSource.removeFromFavorites(
        stationType: stationType,
        stationId: stationId,
      );
      return const Right(null);
    } catch (e) {
      return Left('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<Either<String, List<String>>> getFavoriteStationIds({
    required String stationType,
  }) async {
    try {
      final ids = await _remoteDataSource.getFavoriteStationIds(
        stationType: stationType,
      );
      return Right(ids);
    } catch (e) {
      return Left('Failed to fetch favorites: $e');
    }
  }

  @override
  Future<Either<String, void>> reportAvailability({
    required String stationType,
    required String stationId,
    int? batteriesAvailable,
    int? portsAvailable,
    bool? isOperational,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.reportAvailability(
        stationType: stationType,
        stationId: stationId,
        batteriesAvailable: batteriesAvailable,
        portsAvailable: portsAvailable,
        isOperational: isOperational,
        notes: notes,
      );
      return const Right(null);
    } catch (e) {
      return Left('Failed to report availability: $e');
    }
  }

  @override
  Future<Either<String, int>> fetchStationsFromGoogle({
    required double latitude,
    required double longitude,
    required String stationType,
    int radiusMeters = 10000,
  }) async {
    try {
      final count = await _remoteDataSource.fetchStationsFromGoogle(
        latitude: latitude,
        longitude: longitude,
        stationType: stationType,
        radiusMeters: radiusMeters,
      );
      return Right(count);
    } catch (e) {
      return Left('Failed to fetch from Google: $e');
    }
  }
}
