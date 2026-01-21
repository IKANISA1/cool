import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/ratings_repository.dart';
import '../datasources/ratings_remote_data_source.dart';

/// Implementation of RatingsRepository using Supabase
class RatingsRepositoryImpl implements RatingsRepository {
  final RatingsRemoteDataSource _remoteDataSource;

  RatingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Rating>>> getRatingsForUser(String userId) async {
    try {
      final models = await _remoteDataSource.getRatingsForUser(userId);
      final ratings = models.map((m) => m.toEntity()).toList();
      return Right(ratings);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserRatingStats(String userId) async {
    try {
      final stats = await _remoteDataSource.getUserRatingStats(userId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Rating>> createRating({
    required String toUserId,
    required int rating,
    String? review,
    String? tripId,
  }) async {
    try {
      final model = await _remoteDataSource.createRating(
        toUserId: toUserId,
        rating: rating,
        review: review,
        tripId: tripId,
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasRated({
    required String toUserId,
    String? tripId,
  }) async {
    try {
      final hasRated = await _remoteDataSource.hasRated(
        toUserId: toUserId,
        tripId: tripId,
      );
      return Right(hasRated);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
