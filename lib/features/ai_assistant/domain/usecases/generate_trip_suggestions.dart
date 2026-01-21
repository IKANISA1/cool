import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_trip_request.dart';
import '../repositories/ai_assistant_repository.dart';

/// Use case for generating trip suggestions
///
/// Generates helpful suggestions for completing or correcting
/// a partial trip request.
class GenerateTripSuggestions {
  final AIAssistantRepository repository;

  GenerateTripSuggestions(this.repository);

  /// Generate suggestions for a partial trip request
  Future<Either<Failure, List<TripSuggestion>>> call(
    AITripRequest partialRequest,
  ) async {
    return repository.generateSuggestions(partialRequest);
  }
}
