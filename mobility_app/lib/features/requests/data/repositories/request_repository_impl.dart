import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/request_repository.dart';
import '../datasources/request_remote_datasource.dart';

/// Implementation of RequestRepository
class RequestRepositoryImpl implements RequestRepository {
  final RequestRemoteDataSource remoteDataSource;
  final _log = Logger('RequestRepository');

  RequestRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, RideRequest>> sendRequest(
    SendRequestParams params,
  ) async {
    try {
      final request = await remoteDataSource.sendRequest(
        toUserId: params.toUserId,
        payload: params.payload,
      );
      return Right(request);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to send request', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, RideRequest>> acceptRequest(String requestId) async {
    try {
      final request = await remoteDataSource.acceptRequest(requestId);
      return Right(request);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to accept request', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, RideRequest>> denyRequest(String requestId) async {
    try {
      final request = await remoteDataSource.denyRequest(requestId);
      return Right(request);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to deny request', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelRequest(String requestId) async {
    try {
      await remoteDataSource.cancelRequest(requestId);
      return const Right(null);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to cancel request', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<RideRequest>>> getIncomingRequests() async {
    try {
      final requests = await remoteDataSource.getIncomingRequests();
      return Right(requests);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get incoming requests', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<RideRequest>>> getOutgoingRequests() async {
    try {
      final requests = await remoteDataSource.getOutgoingRequests();
      return Right(requests);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get outgoing requests', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, RideRequest>> getRequest(String requestId) async {
    try {
      final request = await remoteDataSource.getRequest(requestId);
      return Right(request);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to get request', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Stream<Either<Failure, RideRequest>> watchIncomingRequests() {
    return remoteDataSource.watchIncomingRequests().map((request) {
      return Right<Failure, RideRequest>(request);
    }).handleError((error) {
      _log.severe('Error in incoming requests stream', error);
      return Left<Failure, RideRequest>(_mapExceptionToFailure(error));
    });
  }

  @override
  Stream<Either<Failure, RideRequest>> watchRequest(String requestId) {
    return remoteDataSource.watchRequest(requestId).map((request) {
      return Right<Failure, RideRequest>(request);
    }).handleError((error) {
      _log.severe('Error in request stream', error);
      return Left<Failure, RideRequest>(_mapExceptionToFailure(error));
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

    if (message.contains('expired')) {
      return const RequestExpiredFailure();
    }

    return ServerFailure(message: message);
  }
}
