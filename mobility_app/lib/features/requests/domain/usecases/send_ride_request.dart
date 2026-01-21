import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ride_request.dart';
import '../repositories/request_repository.dart';

/// Use case for sending a ride request
class SendRideRequest {
  final RequestRepository repository;

  SendRideRequest(this.repository);

  Future<Either<Failure, RideRequest>> call(SendRequestParams params) async {
    return repository.sendRequest(params);
  }
}
