import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ai_trip_request.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/ai_assistant_remote_datasource.dart';

/// Implementation of AIAssistantRepository
class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final AIAssistantRemoteDataSource remoteDataSource;
  final _log = Logger('AIAssistantRepository');

  AIAssistantRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, AITripRequest>> parseTripIntent(String text) async {
    try {
      final result = await remoteDataSource.parseTripIntent(text);
      return Right(result);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to parse trip intent', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, AITripRequest>> parseVoiceTranscript(
    String transcript,
  ) async {
    // Voice transcripts are parsed the same way as text
    return parseTripIntent(transcript);
  }

  @override
  Future<Either<Failure, List<TripSuggestion>>> generateSuggestions(
    AITripRequest partialRequest,
  ) async {
    try {
      final suggestions = await remoteDataSource.generateSuggestions(partialRequest);
      return Right(suggestions);
    } on Exception catch (e, stackTrace) {
      _log.severe('Failed to generate suggestions', e, stackTrace);
      return Left(_mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, TripLocation>> geocodeLocation(String locationName) async {
    // TODO: Implement geocoding with a geocoding service
    // For now, return a stub location
    return Right(TripLocation(
      name: locationName,
      address: '$locationName, Kigali, Rwanda',
    ));
  }

  @override
  Future<Either<Failure, List<AITripRequest>>> getRecentRequests() async {
    // TODO: Implement caching of recent requests
    return const Right([]);
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    final message = exception.toString();

    if (message.contains('network') || message.contains('connection')) {
      return const NetworkFailure();
    }

    if (message.contains('quota') || message.contains('rate limit')) {
      return const ServerFailure(
        message: 'AI service is busy. Please try again in a moment.',
      );
    }

    return const ServerFailure(
      message: 'Failed to process your request. Please try again.',
    );
  }
}
