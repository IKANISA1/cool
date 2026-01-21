import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/rating.dart';

/// Repository interface for ratings operations
abstract class RatingsRepository {
  /// Get all ratings for a specific user
  Future<Either<Failure, List<Rating>>> getRatingsForUser(String userId);

  /// Get rating statistics for a user (average, count)
  Future<Either<Failure, Map<String, dynamic>>> getUserRatingStats(String userId);

  /// Create a new rating
  Future<Either<Failure, Rating>> createRating({
    required String toUserId,
    required int rating,
    String? review,
    String? tripId,
  });

  /// Check if current user has already rated another user for a trip
  Future<Either<Failure, bool>> hasRated({
    required String toUserId,
    String? tripId,
  });
}
