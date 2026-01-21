import 'package:equatable/equatable.dart';

import '../../domain/entities/ride_request.dart';

/// Base class for all request states
abstract class RequestState extends Equatable {
  /// Current active request (if any)
  final RideRequest? activeRequest;

  /// List of incoming requests
  final List<RideRequest> incomingRequests;

  /// List of outgoing requests
  final List<RideRequest> outgoingRequests;

  const RequestState({
    this.activeRequest,
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
  });

  @override
  List<Object?> get props => [activeRequest, incomingRequests, outgoingRequests];
}

/// Initial state
class RequestInitial extends RequestState {
  const RequestInitial();
}

/// Loading state
class RequestLoading extends RequestState {
  const RequestLoading({
    super.activeRequest,
    super.incomingRequests,
    super.outgoingRequests,
  });
}

/// Request is being sent
class RequestSending extends RequestState {
  const RequestSending({
    super.incomingRequests,
    super.outgoingRequests,
  });
}

/// Request sent successfully, waiting for response
class RequestSent extends RequestState {
  /// The sent request
  final RideRequest request;

  /// Seconds remaining until expiration
  final int secondsRemaining;

  const RequestSent({
    required this.request,
    required this.secondsRemaining,
    super.incomingRequests,
    super.outgoingRequests,
  }) : super(activeRequest: request);

  @override
  List<Object?> get props => [...super.props, secondsRemaining];

  RequestSent copyWith({
    RideRequest? request,
    int? secondsRemaining,
    List<RideRequest>? incomingRequests,
    List<RideRequest>? outgoingRequests,
  }) {
    return RequestSent(
      request: request ?? this.request,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
    );
  }
}

/// Request was accepted
class RequestAccepted extends RequestState {
  /// The accepted request
  final RideRequest request;

  const RequestAccepted({
    required this.request,
    super.incomingRequests,
    super.outgoingRequests,
  }) : super(activeRequest: request);
}

/// Request was denied
class RequestDenied extends RequestState {
  /// The denied request
  final RideRequest request;

  const RequestDenied({
    required this.request,
    super.incomingRequests,
    super.outgoingRequests,
  }) : super(activeRequest: request);
}

/// Request expired
class RequestExpired extends RequestState {
  /// The expired request
  final RideRequest request;

  const RequestExpired({
    required this.request,
    super.incomingRequests,
    super.outgoingRequests,
  }) : super(activeRequest: request);
}

/// Request was cancelled
class RequestCancelled extends RequestState {
  const RequestCancelled({
    super.incomingRequests,
    super.outgoingRequests,
  });
}

/// New incoming request received
class IncomingRequestReceived extends RequestState {
  /// The incoming request
  final RideRequest request;

  const IncomingRequestReceived({
    required this.request,
    super.incomingRequests,
    super.outgoingRequests,
  }) : super(activeRequest: request);
}

/// Requests loaded state
class RequestsLoaded extends RequestState {
  const RequestsLoaded({
    super.activeRequest,
    super.incomingRequests,
    super.outgoingRequests,
  });
}

/// Error state
class RequestError extends RequestState {
  final String message;
  final String? code;

  const RequestError({
    required this.message,
    this.code,
    super.activeRequest,
    super.incomingRequests,
    super.outgoingRequests,
  });

  @override
  List<Object?> get props => [...super.props, message, code];
}
