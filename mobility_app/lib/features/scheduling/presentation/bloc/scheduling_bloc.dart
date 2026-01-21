import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../domain/usecases/create_scheduled_trip.dart';
import '../../domain/usecases/get_scheduled_trips.dart';
import '../../domain/usecases/manage_scheduled_trip.dart';
import 'scheduling_event.dart';
import 'scheduling_state.dart';

/// BLoC for managing scheduled trips
///
/// Handles:
/// - Loading user's trips
/// - Loading upcoming public trips
/// - Creating/updating/deleting trips
/// - Realtime trip updates
class SchedulingBloc extends Bloc<SchedulingEvent, SchedulingState> {
  final CreateScheduledTrip createScheduledTrip;
  final GetScheduledTrips getScheduledTrips;
  final ManageScheduledTrip manageScheduledTrip;

  final _log = Logger('SchedulingBloc');

  StreamSubscription? _tripSubscription;

  SchedulingBloc({
    required this.createScheduledTrip,
    required this.getScheduledTrips,
    required this.manageScheduledTrip,
  }) : super(const SchedulingInitial()) {
    on<LoadMyTrips>(_onLoadMyTrips);
    on<LoadUpcomingTrips>(_onLoadUpcomingTrips);
    on<SearchTrips>(_onSearchTrips);
    on<CreateTrip>(_onCreateTrip);
    on<UpdateTrip>(_onUpdateTrip);
    on<DeleteTrip>(_onDeleteTrip);
    on<SelectTrip>(_onSelectTrip);
    on<ClearSelectedTrip>(_onClearSelectedTrip);
    on<SubscribeToTripUpdates>(_onSubscribeToTripUpdates);
    on<UnsubscribeFromTripUpdates>(_onUnsubscribeFromTripUpdates);
    on<TripUpdated>(_onTripUpdated);
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadMyTrips(
    LoadMyTrips event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Loading my trips');

    emit(SchedulingLoading(
      myTrips: state.myTrips,
      upcomingTrips: state.upcomingTrips,
      selectedTrip: state.selectedTrip,
    ));

    final result = await getScheduledTrips.getMyTrips();

    result.fold(
      (failure) {
        _log.warning('Failed to load my trips: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          upcomingTrips: state.upcomingTrips,
        ));
      },
      (trips) {
        _log.info('Loaded ${trips.length} trips');
        emit(SchedulingLoaded(
          myTrips: trips,
          upcomingTrips: state.upcomingTrips,
          selectedTrip: state.selectedTrip,
        ));
      },
    );
  }

  Future<void> _onLoadUpcomingTrips(
    LoadUpcomingTrips event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Loading upcoming trips');

    emit(SchedulingLoading(
      myTrips: state.myTrips,
      upcomingTrips: state.upcomingTrips,
      tripTypeFilter: event.tripType,
    ));

    final result = await getScheduledTrips.getUpcoming(
      tripType: event.tripType,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        _log.warning('Failed to load upcoming trips: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          myTrips: state.myTrips,
          tripTypeFilter: event.tripType,
        ));
      },
      (trips) {
        _log.info('Loaded ${trips.length} upcoming trips');
        emit(SchedulingLoaded(
          myTrips: state.myTrips,
          upcomingTrips: trips,
          tripTypeFilter: event.tripType,
        ));
      },
    );
  }

  Future<void> _onSearchTrips(
    SearchTrips event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Searching trips');

    emit(SchedulingLoading(
      myTrips: state.myTrips,
      upcomingTrips: state.upcomingTrips,
      tripTypeFilter: event.params.tripType,
    ));

    final result = await getScheduledTrips.search(event.params);

    result.fold(
      (failure) {
        _log.warning('Failed to search trips: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          myTrips: state.myTrips,
        ));
      },
      (trips) {
        _log.info('Found ${trips.length} trips');
        emit(SchedulingLoaded(
          myTrips: state.myTrips,
          upcomingTrips: trips,
          tripTypeFilter: event.params.tripType,
        ));
      },
    );
  }

  Future<void> _onCreateTrip(
    CreateTrip event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Creating trip: ${event.params.tripType}');

    emit(SchedulingLoading(
      myTrips: state.myTrips,
      upcomingTrips: state.upcomingTrips,
    ));

    final result = await createScheduledTrip(event.params);

    result.fold(
      (failure) {
        _log.warning('Failed to create trip: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          myTrips: state.myTrips,
          upcomingTrips: state.upcomingTrips,
        ));
      },
      (trip) {
        _log.info('Trip created: ${trip.id}');
        emit(TripCreated(
          trip: trip,
          myTrips: [...state.myTrips, trip],
          upcomingTrips: state.upcomingTrips,
        ));
      },
    );
  }

  Future<void> _onUpdateTrip(
    UpdateTrip event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Updating trip: ${event.tripId}');

    emit(SchedulingLoading(
      myTrips: state.myTrips,
      upcomingTrips: state.upcomingTrips,
      selectedTrip: state.selectedTrip,
    ));

    final result = await manageScheduledTrip.update(event.tripId, event.params);

    result.fold(
      (failure) {
        _log.warning('Failed to update trip: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          myTrips: state.myTrips,
          upcomingTrips: state.upcomingTrips,
        ));
      },
      (trip) {
        _log.info('Trip updated: ${trip.id}');
        final updatedMyTrips = state.myTrips
            .map((t) => t.id == trip.id ? trip : t)
            .toList();
        emit(SchedulingLoaded(
          myTrips: updatedMyTrips,
          upcomingTrips: state.upcomingTrips,
          selectedTrip: trip,
        ));
      },
    );
  }

  Future<void> _onDeleteTrip(
    DeleteTrip event,
    Emitter<SchedulingState> emit,
  ) async {
    _log.info('Deleting trip: ${event.tripId}');

    final result = await manageScheduledTrip.delete(event.tripId);

    result.fold(
      (failure) {
        _log.warning('Failed to delete trip: ${failure.message}');
        emit(SchedulingError(
          message: failure.message,
          code: failure.code,
          myTrips: state.myTrips,
          upcomingTrips: state.upcomingTrips,
        ));
      },
      (_) {
        _log.info('Trip deleted: ${event.tripId}');
        final updatedMyTrips = state.myTrips
            .where((t) => t.id != event.tripId)
            .toList();
        emit(TripDeleted(
          tripId: event.tripId,
          myTrips: updatedMyTrips,
          upcomingTrips: state.upcomingTrips,
        ));
      },
    );
  }

  void _onSelectTrip(
    SelectTrip event,
    Emitter<SchedulingState> emit,
  ) {
    emit(state.copyWith(selectedTrip: event.trip));
  }

  void _onClearSelectedTrip(
    ClearSelectedTrip event,
    Emitter<SchedulingState> emit,
  ) {
    emit(state.copyWith(clearSelectedTrip: true));
  }

  void _onSubscribeToTripUpdates(
    SubscribeToTripUpdates event,
    Emitter<SchedulingState> emit,
  ) {
    _log.info('Subscribing to trip updates: ${event.tripId}');

    _tripSubscription?.cancel();
    _tripSubscription = manageScheduledTrip.watch(event.tripId).listen(
      (result) {
        result.fold(
          (failure) => _log.warning('Trip update error: ${failure.message}'),
          (trip) => add(TripUpdated(trip)),
        );
      },
      onError: (error) {
        _log.severe('Trip subscription error', error);
      },
    );
  }

  void _onUnsubscribeFromTripUpdates(
    UnsubscribeFromTripUpdates event,
    Emitter<SchedulingState> emit,
  ) {
    _log.info('Unsubscribing from trip updates');
    _tripSubscription?.cancel();
    _tripSubscription = null;
  }

  void _onTripUpdated(
    TripUpdated event,
    Emitter<SchedulingState> emit,
  ) {
    _log.fine('Trip updated: ${event.trip.id}');

    // Update in my trips list
    final updatedMyTrips = state.myTrips
        .map((t) => t.id == event.trip.id ? event.trip : t)
        .toList();

    // Update in upcoming trips list
    final updatedUpcoming = state.upcomingTrips
        .map((t) => t.id == event.trip.id ? event.trip : t)
        .toList();

    emit(SchedulingLoaded(
      myTrips: updatedMyTrips,
      upcomingTrips: updatedUpcoming,
      selectedTrip: state.selectedTrip?.id == event.trip.id
          ? event.trip
          : state.selectedTrip,
    ));
  }
}
