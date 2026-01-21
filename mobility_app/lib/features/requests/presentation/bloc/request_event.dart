import 'package:equatable/equatable.dart';

/// Base class for all request events
abstract class RequestEvent extends Equatable {
  const RequestEvent();

  @override
  List<Object?> get props => [];
}

/// Send a ride request to a user
class SendRequest extends RequestEvent {
  final String toUserId;
  final Map<String, dynamic>? payload;

  const SendRequest({
    required this.toUserId,
    this.payload,
  });

  @override
  List<Object?> get props => [toUserId, payload];
}

/// Accept an incoming request
class AcceptRequest extends RequestEvent {
  final String requestId;

  const AcceptRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Deny an incoming request
class DenyRequest extends RequestEvent {
  final String requestId;

  const DenyRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Cancel an outgoing request
class CancelRequest extends RequestEvent {
  final String requestId;

  const CancelRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Load incoming requests
class LoadIncomingRequests extends RequestEvent {
  const LoadIncomingRequests();
}

/// Load outgoing requests
class LoadOutgoingRequests extends RequestEvent {
  const LoadOutgoingRequests();
}

/// Start watching a specific request
class WatchRequest extends RequestEvent {
  final String requestId;

  const WatchRequest(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Stop watching requests
class StopWatchingRequest extends RequestEvent {
  const StopWatchingRequest();
}

/// Subscribe to incoming requests
class SubscribeToIncomingRequests extends RequestEvent {
  const SubscribeToIncomingRequests();
}

/// Unsubscribe from incoming requests
class UnsubscribeFromIncomingRequests extends RequestEvent {
  const UnsubscribeFromIncomingRequests();
}

/// Request updated from stream
class RequestUpdated extends RequestEvent {
  final dynamic request;

  const RequestUpdated(this.request);

  @override
  List<Object?> get props => [request];
}

/// New incoming request received
class NewIncomingRequest extends RequestEvent {
  final dynamic request;

  const NewIncomingRequest(this.request);

  @override
  List<Object?> get props => [request];
}

/// Countdown tick event
class CountdownTick extends RequestEvent {
  const CountdownTick();
}
