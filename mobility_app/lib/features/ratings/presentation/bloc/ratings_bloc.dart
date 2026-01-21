import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ratings_repository.dart';
import 'ratings_event.dart';
import 'ratings_state.dart';

/// Bloc for managing ratings state
class RatingsBloc extends Bloc<RatingsEvent, RatingsState> {
  final RatingsRepository _repository;

  RatingsBloc(this._repository) : super(const RatingsState()) {
    on<LoadRatingsRequested>(_onLoadRatings);
    on<SubmitRatingRequested>(_onSubmitRating);
    on<ClearRatingsError>(_onClearError);
  }

  Future<void> _onLoadRatings(
    LoadRatingsRequested event,
    Emitter<RatingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final ratingsResult = await _repository.getRatingsForUser(event.userId);
    final statsResult = await _repository.getUserRatingStats(event.userId);

    ratingsResult.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (ratings) {
        statsResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            ratings: ratings,
            error: failure.message,
          )),
          (stats) => emit(state.copyWith(
            isLoading: false,
            ratings: ratings,
            averageRating: (stats['average'] as num).toDouble(),
            totalRatings: stats['count'] as int,
          )),
        );
      },
    );
  }

  Future<void> _onSubmitRating(
    SubmitRatingRequested event,
    Emitter<RatingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, submitSuccess: false));

    final result = await _repository.createRating(
      toUserId: event.toUserId,
      rating: event.rating,
      review: event.review,
      tripId: event.tripId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (rating) => emit(state.copyWith(
        isLoading: false,
        submitSuccess: true,
        ratings: [rating, ...state.ratings],
        totalRatings: state.totalRatings + 1,
      )),
    );
  }

  void _onClearError(
    ClearRatingsError event,
    Emitter<RatingsState> emit,
  ) {
    emit(state.copyWith(error: null));
  }
}
