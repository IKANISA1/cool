import 'package:equatable/equatable.dart';

import '../../domain/entities/scheduled_trip.dart';

/// Base class for scheduling states
abstract class SchedulingState extends Equatable {
  /// User's own trips
  final List<ScheduledTrip> myTrips;

  /// Public upcoming trips
  final List<ScheduledTrip> upcomingTrips;

  /// Currently selected trip
  final ScheduledTrip? selectedTrip;

  /// Current trip type filter
  final TripType? tripTypeFilter;

  const SchedulingState({
    this.myTrips = const [],
    this.upcomingTrips = const [],
    this.selectedTrip,
    this.tripTypeFilter,
  });

  @override
  List<Object?> get props => [
        myTrips,
        upcomingTrips,
        selectedTrip,
        tripTypeFilter,
      ];

  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  });
}

/// Initial state
class SchedulingInitial extends SchedulingState {
  const SchedulingInitial();

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return SchedulingLoaded(
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      selectedTrip: clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),
      tripTypeFilter: tripTypeFilter,
    );
  }
}

/// Loading state
class SchedulingLoading extends SchedulingState {
  const SchedulingLoading({
    super.myTrips,
    super.upcomingTrips,
    super.selectedTrip,
    super.tripTypeFilter,
  });

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return SchedulingLoading(
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      selectedTrip: clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),
      tripTypeFilter: tripTypeFilter,
    );
  }
}

/// Loaded state
class SchedulingLoaded extends SchedulingState {
  const SchedulingLoaded({
    super.myTrips,
    super.upcomingTrips,
    super.selectedTrip,
    super.tripTypeFilter,
  });

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return SchedulingLoaded(
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      selectedTrip: clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),
      tripTypeFilter: tripTypeFilter,
    );
  }
}

/// Error state
class SchedulingError extends SchedulingState {
  final String message;
  final String? code;

  const SchedulingError({
    required this.message,
    this.code,
    super.myTrips,
    super.upcomingTrips,
    super.selectedTrip,
    super.tripTypeFilter,
  });

  @override
  List<Object?> get props => [...super.props, message, code];

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return SchedulingError(
      message: message,
      code: code,
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      selectedTrip: clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),
      tripTypeFilter: tripTypeFilter,
    );
  }
}

/// Trip created successfully
class TripCreated extends SchedulingState {
  final ScheduledTrip trip;

  const TripCreated({
    required this.trip,
    super.myTrips,
    super.upcomingTrips,
    super.tripTypeFilter,
  });

  @override
  List<Object?> get props => [...super.props, trip];

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return TripCreated(
      trip: trip,
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      tripTypeFilter: tripTypeFilter,
    );
  }
}

/// Trip deleted successfully
class TripDeleted extends SchedulingState {
  final String tripId;

  const TripDeleted({
    required this.tripId,
    super.myTrips,
    super.upcomingTrips,
    super.tripTypeFilter,
  });

  @override
  List<Object?> get props => [...super.props, tripId];

  @override
  SchedulingState copyWith({
    List<ScheduledTrip>? myTrips,
    List<ScheduledTrip>? upcomingTrips,
    ScheduledTrip? selectedTrip,
    TripType? tripTypeFilter,
    bool clearSelectedTrip = false,
  }) {
    return TripDeleted(
      tripId: tripId,
      myTrips: myTrips ?? this.myTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      tripTypeFilter: tripTypeFilter,
    );
  }
}
