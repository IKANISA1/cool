import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_trip_request.dart';
import '../repositories/ai_assistant_repository.dart';

/// Use case for parsing natural language trip intent
///
/// Takes text input and uses Gemini AI to extract structured
/// trip information (destination, time, vehicle preference, etc.)
class ParseTripIntent {
  final AIAssistantRepository repository;

  ParseTripIntent(this.repository);

  /// Parse text input
  Future<Either<Failure, AITripRequest>> call(String text) async {
    if (text.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: 'Please describe your trip',
      ));
    }

    return repository.parseTripIntent(text);
  }

  /// Parse voice transcript
  Future<Either<Failure, AITripRequest>> fromVoice(String transcript) async {
    if (transcript.trim().isEmpty) {
      return const Left(ValidationFailure(
        message: 'No speech detected',
      ));
    }

    return repository.parseVoiceTranscript(transcript);
  }
}
