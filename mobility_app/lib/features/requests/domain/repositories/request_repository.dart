import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ride_request.dart';

/// Parameters for sending a ride request
class SendRequestParams {
  /// ID of the recipient user
  final String toUserId;

  /// Optional payload with request details
  final Map<String, dynamic>? payload;

  const SendRequestParams({
    required this.toUserId,
    this.payload,
  });
}

/// Abstract repository interface for ride request operations
abstract class RequestRepository {
  /// Send a ride request to another user
  Future<Either<Failure, RideRequest>> sendRequest(SendRequestParams params);

  /// Accept a ride request
  Future<Either<Failure, RideRequest>> acceptRequest(String requestId);

  /// Deny a ride request
  Future<Either<Failure, RideRequest>> denyRequest(String requestId);

  /// Cancel a pending request (by sender)
  Future<Either<Failure, void>> cancelRequest(String requestId);

  /// Get incoming requests for the current user
  Future<Either<Failure, List<RideRequest>>> getIncomingRequests();

  /// Get outgoing requests from the current user
  Future<Either<Failure, List<RideRequest>>> getOutgoingRequests();

  /// Get a single request by ID
  Future<Either<Failure, RideRequest>> getRequest(String requestId);

  /// Subscribe to realtime updates for incoming requests
  Stream<Either<Failure, RideRequest>> watchIncomingRequests();

  /// Subscribe to realtime updates for a specific request
  Stream<Either<Failure, RideRequest>> watchRequest(String requestId);
}
