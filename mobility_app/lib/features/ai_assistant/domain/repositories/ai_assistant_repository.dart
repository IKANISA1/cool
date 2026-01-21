import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_trip_request.dart';

/// Abstract repository interface for AI assistant operations
abstract class AIAssistantRepository {
  /// Parse natural language text into a structured trip request
  Future<Either<Failure, AITripRequest>> parseTripIntent(String text);

  /// Parse voice transcript into a structured trip request
  Future<Either<Failure, AITripRequest>> parseVoiceTranscript(String transcript);

  /// Generate suggestions based on partial trip info
  Future<Either<Failure, List<TripSuggestion>>> generateSuggestions(
    AITripRequest partialRequest,
  );

  /// Geocode a location name to coordinates
  Future<Either<Failure, TripLocation>> geocodeLocation(String locationName);

  /// Get recent trip requests for suggestions
  Future<Either<Failure, List<AITripRequest>>> getRecentRequests();
}
