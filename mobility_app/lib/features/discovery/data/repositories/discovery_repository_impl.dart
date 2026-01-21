import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/nearby_user.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

/// Implementation of DiscoveryRepository
///
/// Handles data transformation between data layer and domain layer,
/// as well as error handling and mapping.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;
  final _log = Logger('DiscoveryRepository');

  DiscoveryRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, NearbyUsersResult>> getNearbyUsers(
    NearbyUsersParams params,
  ) async {
    try {
      final users = await remoteDataSource.getNearbyUsers(params);
      
      // Determine if there are more results
      // If we got a full page, assume there might be more
      final hasMore = users.length >= params.pageSize;
      
      return Right(NearbyUsersResult(
        users: users,
        hasMore: hasMore,
        totalCount: users.length,
      ));
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get nearby users', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Either<Failure, List<NearbyUser>>> watchNearbyUsers(
    NearbyUsersParams params,
  ) {
    return remoteDataSource.watchNearbyUsers(params).map((users) {
      return Right<Failure, List<NearbyUser>>(users);
    }).handleError((error) {
      _log.severe('Error in nearby users stream', error);
      return Left<Failure, List<NearbyUser>>(_mapExceptionToFailure(error));
    });
  }

  @override
  Future<Either<Failure, bool>> toggleOnlineStatus(bool isOnline) async {
    try {
      final result = await remoteDataSource.setOnlineStatus(isOnline);
      return Right(result);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to toggle online status', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
  }) async {
    try {
      await remoteDataSource.updateLocation(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        heading: heading,
        speed: speed,
      );
      return const Right(null);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to update location', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> getOnlineStatus() async {
    try {
      final status = await remoteDataSource.getOnlineStatus();
      return Right(status);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get online status', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<NearbyUser>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to search users', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  /// Map exceptions to failure types
  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString();
    
    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure();
    }
    
    if (message.contains('auth') || message.contains('unauthorized')) {
      return const AuthFailure();
    }
    
    if (message.contains('location') || message.contains('permission')) {
      return const LocationPermissionFailure();
    }
    
    return ServerFailure(message: message);
  }
}
