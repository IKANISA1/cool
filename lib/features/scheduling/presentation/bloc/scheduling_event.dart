import 'package:equatable/equatable.dart';

import '../../domain/entities/scheduled_trip.dart';
import '../../domain/repositories/scheduling_repository.dart';

/// Base class for scheduling events
abstract class SchedulingEvent extends Equatable {
  const SchedulingEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's trips
class LoadMyTrips extends SchedulingEvent {
  const LoadMyTrips();
}

/// Load upcoming public trips
class LoadUpcomingTrips extends SchedulingEvent {
  final TripType? tripType;
  final int limit;

  const LoadUpcomingTrips({
    this.tripType,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [tripType, limit];
}

/// Search trips with filters
class SearchTrips extends SchedulingEvent {
  final SearchTripsParams params;

  const SearchTrips(this.params);

  @override
  List<Object?> get props => [params];
}

/// Create a new trip
class CreateTrip extends SchedulingEvent {
  final ScheduledTripParams params;

  const CreateTrip(this.params);

  @override
  List<Object?> get props => [params];
}

/// Update an existing trip
class UpdateTrip extends SchedulingEvent {
  final String tripId;
  final ScheduledTripParams params;

  const UpdateTrip(this.tripId, this.params);

  @override
  List<Object?> get props => [tripId, params];
}

/// Delete a trip
class DeleteTrip extends SchedulingEvent {
  final String tripId;

  const DeleteTrip(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Select a trip for viewing
class SelectTrip extends SchedulingEvent {
  final ScheduledTrip trip;

  const SelectTrip(this.trip);

  @override
  List<Object?> get props => [trip];
}

/// Clear selected trip
class ClearSelectedTrip extends SchedulingEvent {
  const ClearSelectedTrip();
}

/// Subscribe to trip updates
class SubscribeToTripUpdates extends SchedulingEvent {
  final String tripId;

  const SubscribeToTripUpdates(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Unsubscribe from trip updates
class UnsubscribeFromTripUpdates extends SchedulingEvent {
  const UnsubscribeFromTripUpdates();
}

/// Internal event when trip is updated
class TripUpdated extends SchedulingEvent {
  final ScheduledTrip trip;

  const TripUpdated(this.trip);

  @override
  List<Object?> get props => [trip];
}
