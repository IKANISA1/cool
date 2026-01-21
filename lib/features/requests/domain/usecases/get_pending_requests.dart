import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ride_request.dart';
import '../repositories/request_repository.dart';

/// Use case for getting pending requests
class GetPendingRequests {
  final RequestRepository repository;

  GetPendingRequests(this.repository);

  /// Get incoming requests
  Future<Either<Failure, List<RideRequest>>> getIncoming() async {
    return repository.getIncomingRequests();
  }

  /// Get outgoing requests
  Future<Either<Failure, List<RideRequest>>> getOutgoing() async {
    return repository.getOutgoingRequests();
  }

  /// Watch for incoming requests
  Stream<Either<Failure, RideRequest>> watchIncoming() {
    return repository.watchIncomingRequests();
  }
}
