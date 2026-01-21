import 'package:equatable/equatable.dart';

/// Base class for AI assistant events
abstract class AIAssistantEvent extends Equatable {
  const AIAssistantEvent();

  @override
  List<Object?> get props => [];
}

/// Parse text input for trip intent
class ParseTextInput extends AIAssistantEvent {
  final String text;

  const ParseTextInput(this.text);

  @override
  List<Object?> get props => [text];
}

/// Start voice recording
class StartVoiceInput extends AIAssistantEvent {
  const StartVoiceInput();
}

/// Stop voice recording and process
class StopVoiceInput extends AIAssistantEvent {
  final String transcript;

  const StopVoiceInput(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

/// Cancel voice recording
class CancelVoiceInput extends AIAssistantEvent {
  const CancelVoiceInput();
}

/// Received partial transcription result
class VoicePartialResult extends AIAssistantEvent {
  final String transcript;

  const VoicePartialResult(this.transcript);

  @override
  List<Object?> get props => [transcript];
}

/// Apply a suggestion
class ApplySuggestion extends AIAssistantEvent {
  final dynamic suggestion;

  const ApplySuggestion(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

/// Edit the parsed request
class EditParsedRequest extends AIAssistantEvent {
  final dynamic updatedRequest;

  const EditParsedRequest(this.updatedRequest);

  @override
  List<Object?> get props => [updatedRequest];
}

/// Confirm and proceed with the request
class ConfirmTrip extends AIAssistantEvent {
  const ConfirmTrip();
}

/// Reset to initial state
class ResetAssistant extends AIAssistantEvent {
  const ResetAssistant();
}

/// Generate suggestions for partial request
class GenerateSuggestions extends AIAssistantEvent {
  const GenerateSuggestions();
}
