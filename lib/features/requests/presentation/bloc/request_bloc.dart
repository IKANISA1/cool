import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../domain/entities/ride_request.dart';
import '../../domain/repositories/request_repository.dart';
import '../../domain/usecases/get_pending_requests.dart';
import '../../domain/usecases/respond_to_request.dart';
import '../../domain/usecases/send_ride_request.dart';
import 'request_event.dart';
import 'request_state.dart';

/// BLoC for managing ride requests
///
/// Handles:
/// - Sending ride requests
/// - Accepting/denying incoming requests
/// - 60-second countdown timer
/// - Realtime request updates
class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final SendRideRequest sendRideRequest;
  final RespondToRequest respondToRequest;
  final GetPendingRequests getPendingRequests;

  final _log = Logger('RequestBloc');

  Timer? _countdownTimer;
  StreamSubscription? _requestSubscription;
  StreamSubscription? _incomingSubscription;

  RequestBloc({
    required this.sendRideRequest,
    required this.respondToRequest,
    required this.getPendingRequests,
  }) : super(const RequestInitial()) {
    on<SendRequest>(_onSendRequest);
    on<AcceptRequest>(_onAcceptRequest);
    on<DenyRequest>(_onDenyRequest);
    on<CancelRequest>(_onCancelRequest);
    on<LoadIncomingRequests>(_onLoadIncomingRequests);
    on<LoadOutgoingRequests>(_onLoadOutgoingRequests);
    on<WatchRequest>(_onWatchRequest);
    on<StopWatchingRequest>(_onStopWatchingRequest);
    on<SubscribeToIncomingRequests>(_onSubscribeToIncomingRequests);
    on<UnsubscribeFromIncomingRequests>(_onUnsubscribeFromIncomingRequests);
    on<RequestUpdated>(_onRequestUpdated);
    on<NewIncomingRequest>(_onNewIncomingRequest);
    on<CountdownTick>(_onCountdownTick);
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _requestSubscription?.cancel();
    _incomingSubscription?.cancel();
    return super.close();
  }

  void _startCountdown(RideRequest request) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const CountdownTick());
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _onSendRequest(
    SendRequest event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Sending request to: ${event.toUserId}');

    emit(RequestSending(
      incomingRequests: state.incomingRequests,
      outgoingRequests: state.outgoingRequests,
    ));

    final params = SendRequestParams(
      toUserId: event.toUserId,
      payload: event.payload,
    );

    final result = await sendRideRequest(params);

    result.fold(
      (failure) {
        _log.warning('Failed to send request: ${failure.message}');
        emit(RequestError(
          message: failure.message,
          code: failure.code,
          incomingRequests: state.incomingRequests,
          outgoingRequests: state.outgoingRequests,
        ));
      },
      (request) {
        _log.info('Request sent successfully: ${request.id}');
        emit(RequestSent(
          request: request,
          secondsRemaining: request.secondsRemaining,
          incomingRequests: state.incomingRequests,
          outgoingRequests: [...state.outgoingRequests, request],
        ));
        _startCountdown(request);
        add(WatchRequest(request.id));
      },
    );
  }

  Future<void> _onAcceptRequest(
    AcceptRequest event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Accepting request: ${event.requestId}');

    emit(RequestLoading(
      activeRequest: state.activeRequest,
      incomingRequests: state.incomingRequests,
      outgoingRequests: state.outgoingRequests,
    ));

    final result = await respondToRequest.accept(event.requestId);

    result.fold(
      (failure) {
        _log.warning('Failed to accept request: ${failure.message}');
        emit(RequestError(
          message: failure.message,
          code: failure.code,
          incomingRequests: state.incomingRequests,
          outgoingRequests: state.outgoingRequests,
        ));
      },
      (request) {
        _log.info('Request accepted: ${request.id}');
        final updatedIncoming = state.incomingRequests
            .where((r) => r.id != request.id)
            .toList();
        emit(RequestAccepted(
          request: request,
          incomingRequests: updatedIncoming,
          outgoingRequests: state.outgoingRequests,
        ));
      },
    );
  }

  Future<void> _onDenyRequest(
    DenyRequest event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Denying request: ${event.requestId}');

    emit(RequestLoading(
      activeRequest: state.activeRequest,
      incomingRequests: state.incomingRequests,
      outgoingRequests: state.outgoingRequests,
    ));

    final result = await respondToRequest.deny(event.requestId);

    result.fold(
      (failure) {
        _log.warning('Failed to deny request: ${failure.message}');
        emit(RequestError(
          message: failure.message,
          code: failure.code,
          incomingRequests: state.incomingRequests,
          outgoingRequests: state.outgoingRequests,
        ));
      },
      (request) {
        _log.info('Request denied: ${request.id}');
        final updatedIncoming = state.incomingRequests
            .where((r) => r.id != request.id)
            .toList();
        emit(RequestDenied(
          request: request,
          incomingRequests: updatedIncoming,
          outgoingRequests: state.outgoingRequests,
        ));
      },
    );
  }

  Future<void> _onCancelRequest(
    CancelRequest event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Cancelling request: ${event.requestId}');

    _stopCountdown();
    add(const StopWatchingRequest());

    final updatedOutgoing = state.outgoingRequests
        .where((r) => r.id != event.requestId)
        .toList();

    emit(RequestCancelled(
      incomingRequests: state.incomingRequests,
      outgoingRequests: updatedOutgoing,
    ));
  }

  Future<void> _onLoadIncomingRequests(
    LoadIncomingRequests event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Loading incoming requests');

    emit(RequestLoading(
      activeRequest: state.activeRequest,
      incomingRequests: state.incomingRequests,
      outgoingRequests: state.outgoingRequests,
    ));

    final result = await getPendingRequests.getIncoming();

    result.fold(
      (failure) {
        _log.warning('Failed to load incoming requests: ${failure.message}');
        emit(RequestError(
          message: failure.message,
          code: failure.code,
          outgoingRequests: state.outgoingRequests,
        ));
      },
      (requests) {
        _log.info('Loaded ${requests.length} incoming requests');
        emit(RequestsLoaded(
          incomingRequests: requests,
          outgoingRequests: state.outgoingRequests,
        ));
      },
    );
  }

  Future<void> _onLoadOutgoingRequests(
    LoadOutgoingRequests event,
    Emitter<RequestState> emit,
  ) async {
    _log.info('Loading outgoing requests');

    emit(RequestLoading(
      activeRequest: state.activeRequest,
      incomingRequests: state.incomingRequests,
      outgoingRequests: state.outgoingRequests,
    ));

    final result = await getPendingRequests.getOutgoing();

    result.fold(
      (failure) {
        _log.warning('Failed to load outgoing requests: ${failure.message}');
        emit(RequestError(
          message: failure.message,
          code: failure.code,
          incomingRequests: state.incomingRequests,
        ));
      },
      (requests) {
        _log.info('Loaded ${requests.length} outgoing requests');
        emit(RequestsLoaded(
          incomingRequests: state.incomingRequests,
          outgoingRequests: requests,
        ));
      },
    );
  }

  void _onWatchRequest(
    WatchRequest event,
    Emitter<RequestState> emit,
  ) {
    _log.info('Watching request: ${event.requestId}');

    _requestSubscription?.cancel();
    // Note: Would use repository.watchRequest here in full implementation
  }

  void _onStopWatchingRequest(
    StopWatchingRequest event,
    Emitter<RequestState> emit,
  ) {
    _log.info('Stopping request watch');
    _requestSubscription?.cancel();
    _requestSubscription = null;
  }

  void _onSubscribeToIncomingRequests(
    SubscribeToIncomingRequests event,
    Emitter<RequestState> emit,
  ) {
    _log.info('Subscribing to incoming requests');

    _incomingSubscription?.cancel();
    _incomingSubscription = getPendingRequests.watchIncoming().listen(
      (result) {
        result.fold(
          (failure) => _log.warning('Incoming request error: ${failure.message}'),
          (request) => add(NewIncomingRequest(request)),
        );
      },
      onError: (error) {
        _log.severe('Incoming requests subscription error', error);
      },
    );
  }

  void _onUnsubscribeFromIncomingRequests(
    UnsubscribeFromIncomingRequests event,
    Emitter<RequestState> emit,
  ) {
    _log.info('Unsubscribing from incoming requests');
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
  }

  void _onRequestUpdated(
    RequestUpdated event,
    Emitter<RequestState> emit,
  ) {
    final request = event.request as RideRequest;
    _log.fine('Request updated: ${request.id}, status: ${request.status}');

    if (request.isAccepted) {
      _stopCountdown();
      emit(RequestAccepted(
        request: request,
        incomingRequests: state.incomingRequests,
        outgoingRequests: state.outgoingRequests,
      ));
    } else if (request.isDenied) {
      _stopCountdown();
      emit(RequestDenied(
        request: request,
        incomingRequests: state.incomingRequests,
        outgoingRequests: state.outgoingRequests,
      ));
    } else if (request.isExpired) {
      _stopCountdown();
      emit(RequestExpired(
        request: request,
        incomingRequests: state.incomingRequests,
        outgoingRequests: state.outgoingRequests,
      ));
    }
  }

  void _onNewIncomingRequest(
    NewIncomingRequest event,
    Emitter<RequestState> emit,
  ) {
    final request = event.request as RideRequest;
    _log.info('New incoming request: ${request.id}');

    emit(IncomingRequestReceived(
      request: request,
      incomingRequests: [...state.incomingRequests, request],
      outgoingRequests: state.outgoingRequests,
    ));
  }

  void _onCountdownTick(
    CountdownTick event,
    Emitter<RequestState> emit,
  ) {
    if (state is RequestSent) {
      final currentState = state as RequestSent;
      final newSeconds = currentState.secondsRemaining - 1;

      if (newSeconds <= 0) {
        _stopCountdown();
        emit(RequestExpired(
          request: currentState.request,
          incomingRequests: state.incomingRequests,
          outgoingRequests: state.outgoingRequests,
        ));
      } else {
        emit(currentState.copyWith(secondsRemaining: newSeconds));
      }
    }
  }
}
