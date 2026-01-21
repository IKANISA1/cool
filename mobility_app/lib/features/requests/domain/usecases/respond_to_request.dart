import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ride_request.dart';
import '../repositories/request_repository.dart';

/// Use case for responding to a ride request (accept or deny)
class RespondToRequest {
  final RequestRepository repository;

  RespondToRequest(this.repository);

  /// Accept the request
  Future<Either<Failure, RideRequest>> accept(String requestId) async {
    return repository.acceptRequest(requestId);
  }

  /// Deny the request
  Future<Either<Failure, RideRequest>> deny(String requestId) async {
    return repository.denyRequest(requestId);
  }
}
