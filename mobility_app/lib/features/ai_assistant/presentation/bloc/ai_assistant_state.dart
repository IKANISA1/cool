import 'package:equatable/equatable.dart';

import '../../domain/entities/ai_trip_request.dart';

/// Base class for AI assistant states
abstract class AIAssistantState extends Equatable {
  /// Current parsed request (if any)
  final AITripRequest? parsedRequest;

  /// List of suggestions
  final List<TripSuggestion> suggestions;

  const AIAssistantState({
    this.parsedRequest,
    this.suggestions = const [],
  });

  @override
  List<Object?> get props => [parsedRequest, suggestions];
}

/// Initial idle state
class AIAssistantIdle extends AIAssistantState {
  const AIAssistantIdle({
    super.parsedRequest,
    super.suggestions,
  });
}

/// Listening for voice input
class AIAssistantListening extends AIAssistantState {
  /// Current decibel level for animation
  final double volume;

  /// Partial transcript (live)
  final String partialTranscript;

  const AIAssistantListening({
    this.volume = 0.0,
    this.partialTranscript = '',
    super.parsedRequest,
    super.suggestions,
  });

  @override
  List<Object?> get props => [...super.props, volume, partialTranscript];

  AIAssistantListening copyWith({
    double? volume,
    String? partialTranscript,
  }) {
    return AIAssistantListening(
      volume: volume ?? this.volume,
      partialTranscript: partialTranscript ?? this.partialTranscript,
      parsedRequest: parsedRequest,
      suggestions: suggestions,
    );
  }
}

/// Processing input (parsing with AI)
class AIAssistantProcessing extends AIAssistantState {
  /// The input being processed
  final String input;

  /// Whether this is voice input
  final bool isVoice;

  const AIAssistantProcessing({
    required this.input,
    this.isVoice = false,
    super.parsedRequest,
    super.suggestions,
  });

  @override
  List<Object?> get props => [...super.props, input, isVoice];
}

/// Successfully parsed trip intent
class AIAssistantSuccess extends AIAssistantState {
  const AIAssistantSuccess({
    required AITripRequest parsedRequest,
    super.suggestions,
  }) : super(parsedRequest: parsedRequest);
}

/// Error state
class AIAssistantError extends AIAssistantState {
  final String message;
  final String? code;

  const AIAssistantError({
    required this.message,
    this.code,
    super.parsedRequest,
    super.suggestions,
  });

  @override
  List<Object?> get props => [...super.props, message, code];
}

/// Trip confirmed, ready to proceed
class AIAssistantTripConfirmed extends AIAssistantState {
  const AIAssistantTripConfirmed({
    required AITripRequest parsedRequest,
  }) : super(parsedRequest: parsedRequest);
}
