import 'package:equatable/equatable.dart';

/// Events for the RatingsBloc
abstract class RatingsEvent extends Equatable {
  const RatingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load ratings for a specific user
class LoadRatingsRequested extends RatingsEvent {
  final String userId;

  const LoadRatingsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Submit a new rating
class SubmitRatingRequested extends RatingsEvent {
  final String toUserId;
  final int rating;
  final String? review;
  final String? tripId;

  const SubmitRatingRequested({
    required this.toUserId,
    required this.rating,
    this.review,
    this.tripId,
  });

  @override
  List<Object?> get props => [toUserId, rating, review, tripId];
}

/// Clear any error state
class ClearRatingsError extends RatingsEvent {
  const ClearRatingsError();
}
