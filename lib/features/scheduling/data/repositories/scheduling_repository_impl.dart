import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/scheduled_trip.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../datasources/scheduling_remote_datasource.dart';

/// Implementation of SchedulingRepository
class SchedulingRepositoryImpl implements SchedulingRepository {
  final SchedulingRemoteDataSource remoteDataSource;
  final _log = Logger('SchedulingRepository');

  SchedulingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ScheduledTrip>> createTrip(
    ScheduledTripParams params,
  ) async {
    try {
      final trip = await remoteDataSource.createTrip(params);
      return Right(trip);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to create trip', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ScheduledTrip>> updateTrip(
    String tripId,
    ScheduledTripParams params,
  ) async {
    try {
      final trip = await remoteDataSource.updateTrip(tripId, params);
      return Right(trip);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to update trip', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String tripId) async {
    try {
      await remoteDataSource.deleteTrip(tripId);
      return const Right(null);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to delete trip', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, ScheduledTrip>> getTrip(String tripId) async {
    try {
      final trip = await remoteDataSource.getTrip(tripId);
      return Right(trip);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get trip', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledTrip>>> getMyTrips() async {
    try {
      final trips = await remoteDataSource.getMyTrips();
      return Right(trips);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get my trips', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledTrip>>> searchTrips(
    SearchTripsParams params,
  ) async {
    try {
      final trips = await remoteDataSource.searchTrips(params);
      return Right(trips);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to search trips', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ScheduledTrip>>> getUpcomingTrips({
    TripType? tripType,
    int limit = 20,
  }) async {
    try {
      final trips = await remoteDataSource.getUpcomingTrips(
        tripType: tripType,
        limit: limit,
      );
      return Right(trips);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get upcoming trips', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Either<Failure, ScheduledTrip>> watchTrip(String tripId) {
    return remoteDataSource.watchTrip(tripId).map((trip) {
      return Right<Failure, ScheduledTrip>(trip);
    }).handleError((error) {
      _log.severe('Error watching trip', error);
      return Left<Failure, ScheduledTrip>(_mapExceptionToFailure(error));
    });
  }

  @override
  Stream<Either<Failure, List<ScheduledTrip>>> watchNearbyTrips(
    SearchTripsParams params,
  ) {
    return remoteDataSource.watchNearbyTrips(params).map((trips) {
      return Right<Failure, List<ScheduledTrip>>(trips);
    }).handleError((error) {
      _log.severe('Error watching nearby trips', error);
      return Left<Failure, List<ScheduledTrip>>(_mapExceptionToFailure(error));
    });
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString();

    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure();
    }

    if (message.contains('auth') || message.contains('unauthorized')) {
      return const AuthFailure();
    }

    return ServerFailure(message: message);
  }
}
