import 'package:equatable/equatable.dart';
import '../../domain/entities/rating.dart';

/// State for the RatingsBloc
class RatingsState extends Equatable {
  final bool isLoading;
  final List<Rating> ratings;
  final double averageRating;
  final int totalRatings;
  final String? error;
  final bool submitSuccess;

  const RatingsState({
    this.isLoading = false,
    this.ratings = const [],
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.error,
    this.submitSuccess = false,
  });

  RatingsState copyWith({
    bool? isLoading,
    List<Rating>? ratings,
    double? averageRating,
    int? totalRatings,
    String? error,
    bool? submitSuccess,
  }) {
    return RatingsState(
      isLoading: isLoading ?? this.isLoading,
      ratings: ratings ?? this.ratings,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      error: error,
      submitSuccess: submitSuccess ?? this.submitSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        ratings,
        averageRating,
        totalRatings,
        error,
        submitSuccess,
      ];
}
