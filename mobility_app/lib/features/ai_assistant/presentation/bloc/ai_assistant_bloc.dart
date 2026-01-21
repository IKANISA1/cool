import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import '../../../../core/services/speech_service.dart';
import '../../domain/entities/ai_trip_request.dart';
import '../../domain/usecases/generate_trip_suggestions.dart';
import '../../domain/usecases/parse_trip_intent.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

/// BLoC for AI-powered trip assistant
///
/// Handles:
/// - Text input parsing via Gemini
/// - Voice input transcription and parsing
/// - Trip suggestion generation
/// - Request confirmation flow
class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final ParseTripIntent parseTripIntent;
  final GenerateTripSuggestions generateTripSuggestions;

  final _log = Logger('AIAssistantBloc');

  AIAssistantBloc({
    required this.parseTripIntent,
    required this.generateTripSuggestions,
    required this.speechService,
  }) : super(const AIAssistantIdle()) {
    on<ParseTextInput>(_onParseTextInput);
    on<StartVoiceInput>(_onStartVoiceInput);
    on<StopVoiceInput>(_onStopVoiceInput);
    on<CancelVoiceInput>(_onCancelVoiceInput);
    on<ApplySuggestion>(_onApplySuggestion);
    on<EditParsedRequest>(_onEditParsedRequest);
    on<ConfirmTrip>(_onConfirmTrip);
    on<ResetAssistant>(_onResetAssistant);
    on<GenerateSuggestions>(_onGenerateSuggestions);
    on<VoicePartialResult>(_onVoicePartialResult);
  }

  final SpeechService speechService;

  void _onVoicePartialResult(
    VoicePartialResult event,
    Emitter<AIAssistantState> emit,
  ) {
    if (state is AIAssistantListening) {
      emit((state as AIAssistantListening).copyWith(
        partialTranscript: event.transcript,
      ));
    }
  }

  Future<void> _onParseTextInput(
    ParseTextInput event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      return;
    }

    _log.info('Parsing text input: "${event.text}"');

    emit(AIAssistantProcessing(
      input: event.text,
      isVoice: false,
      parsedRequest: state.parsedRequest,
      suggestions: state.suggestions,
    ));

    final result = await parseTripIntent(event.text);

    result.fold(
      (failure) {
        _log.warning('Failed to parse: ${failure.message}');
        emit(AIAssistantError(
          message: failure.message,
          code: failure.code,
          parsedRequest: state.parsedRequest,
          suggestions: state.suggestions,
        ));
      },
      (tripRequest) {
        _log.info('Parsed successfully: ${tripRequest.destination?.name}');
        emit(AIAssistantSuccess(
          parsedRequest: tripRequest,
          suggestions: state.suggestions,
        ));

        // Auto-generate suggestions if request is incomplete
        if (!tripRequest.isValid) {
          add(const GenerateSuggestions());
        }
      },
    );
  }

  Future<void> _onStartVoiceInput(
    StartVoiceInput event,
    Emitter<AIAssistantState> emit,
  ) async {
    _log.info('Starting voice input');
    
    final initialized = await speechService.initialize();
    if (!initialized) {
      emit(AIAssistantError(
        message: 'Speech recognition not available',
        code: 'SPEECH_INIT_FAILED',
        parsedRequest: state.parsedRequest,
        suggestions: state.suggestions,
      ));
      return;
    }

    emit(AIAssistantListening(
      parsedRequest: state.parsedRequest,
      suggestions: state.suggestions,
    ));

    await speechService.startListening(
      onResult: (text) {
        add(VoicePartialResult(text));
      },
    );
  }

  Future<void> _onStopVoiceInput(
    StopVoiceInput event,
    Emitter<AIAssistantState> emit,
  ) async {
    await speechService.stopListening();
    
    // Use the transcript from the event if provided (simulated), 
    // otherwise getting it from service would be ideal but service currently returns via callback.
    // However, since we are moving to real integration:
    // The service doesn't easily return the "final" text on stop, it delivers it via onResult.
    // We should probably rely on the UI to pass the final text if it was tracking it,
    // OR change the service to return the text.
    // For now, let's assume the UI was receiving partials and passes the final one here,
    // OR we rely on what the service captured.
    
    // If the event has text (e.g. from simulation or UI buffer), use it.
    String transcript = event.transcript;
    
    if (transcript.isEmpty) {
        // Fallback: This might happen if UI didn't pass it. 
        // Real implementation would need the Bloc to listen to stream.
        // For this step, we will proceed assuming the UI passes the transcript 
        // or we just handle empty.
        emit(AIAssistantIdle(
          parsedRequest: state.parsedRequest,
          suggestions: state.suggestions,
        ));
        return;
    }

    _log.info('Processing voice transcript: "$transcript"');

    emit(AIAssistantProcessing(
      input: transcript,
      isVoice: true,
      parsedRequest: state.parsedRequest,
      suggestions: state.suggestions,
    ));

    // Use regular parseTripIntent for now as fromVoice alias in the state machine 
    // effectively does the same but maybe with different error handling.
    // The previous code called parseTripIntent.fromVoice but that method doesn't exist on the use case.
    // It was likely a "conceptual" method. Use the regular one.
    final result = await parseTripIntent(transcript);

    result.fold(
      (failure) {
        _log.warning('Failed to parse voice: ${failure.message}');
        emit(AIAssistantError(
          message: failure.message,
          code: failure.code,
          parsedRequest: state.parsedRequest,
          suggestions: state.suggestions,
        ));
      },
      (tripRequest) {
        _log.info('Voice parsed successfully');
        emit(AIAssistantSuccess(
          parsedRequest: tripRequest,
          suggestions: state.suggestions,
        ));

        if (!tripRequest.isValid) {
          add(const GenerateSuggestions());
        }
      },
    );
  }

  Future<void> _onCancelVoiceInput(
    CancelVoiceInput event,
    Emitter<AIAssistantState> emit,
  ) async {
    _log.info('Cancelling voice input');
    await speechService.cancelListening();
    emit(AIAssistantIdle(
      parsedRequest: state.parsedRequest,
      suggestions: state.suggestions,
    ));
  }

  void _onApplySuggestion(
    ApplySuggestion event,
    Emitter<AIAssistantState> emit,
  ) {
    final suggestion = event.suggestion as TripSuggestion;
    _log.info('Applying suggestion: ${suggestion.text}');

    // If suggestion has a value, use it to update the request
    if (suggestion.value != null) {
      add(ParseTextInput(suggestion.value!));
    }
  }

  void _onEditParsedRequest(
    EditParsedRequest event,
    Emitter<AIAssistantState> emit,
  ) {
    final updatedRequest = event.updatedRequest as AITripRequest;
    _log.info('Editing parsed request');

    emit(AIAssistantSuccess(
      parsedRequest: updatedRequest,
      suggestions: state.suggestions,
    ));
  }

  void _onConfirmTrip(
    ConfirmTrip event,
    Emitter<AIAssistantState> emit,
  ) {
    if (state.parsedRequest == null) {
      return;
    }

    _log.info('Confirming trip: ${state.parsedRequest!.destination?.name}');

    emit(AIAssistantTripConfirmed(
      parsedRequest: state.parsedRequest!,
    ));
  }

  void _onResetAssistant(
    ResetAssistant event,
    Emitter<AIAssistantState> emit,
  ) {
    _log.info('Resetting assistant');
    emit(const AIAssistantIdle());
  }

  Future<void> _onGenerateSuggestions(
    GenerateSuggestions event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state.parsedRequest == null) {
      return;
    }

    _log.info('Generating suggestions');

    final result = await generateTripSuggestions(state.parsedRequest!);

    result.fold(
      (failure) {
        _log.warning('Failed to generate suggestions: ${failure.message}');
        // Don't emit error, just keep current state
      },
      (suggestions) {
        _log.info('Generated ${suggestions.length} suggestions');
        if (state is AIAssistantSuccess) {
          emit(AIAssistantSuccess(
            parsedRequest: state.parsedRequest!,
            suggestions: suggestions,
          ));
        }
      },
    );
  }
}
