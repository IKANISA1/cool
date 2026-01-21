import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../widgets/ai_response_card.dart';
import '../widgets/trip_suggestion_card.dart';
import '../widgets/voice_input_button.dart';

/// AI Assistant page for natural language trip scheduling
///
/// Features:
/// - Text input for describing trips
/// - Voice input with live transcription
/// - AI-powered intent parsing via Gemini
/// - Smart suggestions for incomplete requests
/// - Confirmation flow before searching
class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final double _voiceVolume = 0.0;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    context.read<AIAssistantBloc>().add(ParseTextInput(text));
    _focusNode.unfocus();
  }

  void _startVoice() {
    HapticFeedback.mediumImpact();
    context.read<AIAssistantBloc>().add(const StartVoiceInput());
  }

  void _stopVoice() {
    HapticFeedback.lightImpact();
    final state = context.read<AIAssistantBloc>().state;
    final transcript = (state is AIAssistantListening) ? state.partialTranscript : '';
    
    context.read<AIAssistantBloc>().add(
          StopVoiceInput(transcript),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Trip Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AIAssistantBloc>().add(const ResetAssistant());
              _textController.clear();
            },
          ),
        ],
      ),
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.03),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content area
              Expanded(
                child: BlocConsumer<AIAssistantBloc, AIAssistantState>(
                  listener: (context, state) {
                    if (state is AIAssistantTripConfirmed) {
                      // Navigate to search/discovery with parsed trip
                      Navigator.pushNamed(
                        context,
                        '/discover',
                        arguments: state.parsedRequest,
                      );
                    }
                  },
                  builder: (context, state) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome text when idle
                          if (state is AIAssistantIdle &&
                              state.parsedRequest == null)
                            _buildWelcome(theme),

                          // Listening indicator
                          if (state is AIAssistantListening)
                            _buildListeningState(state, theme),

                          // Processing indicator
                          if (state is AIAssistantProcessing)
                            _buildProcessingState(state, theme),

                          // Error message
                          if (state is AIAssistantError)
                            _buildErrorState(state, theme),

                          // Parsed result
                          if (state.parsedRequest != null &&
                              state is! AIAssistantProcessing)
                            AIResponseCard(
                              request: state.parsedRequest!,
                              onEdit: () {
                                _textController.text =
                                    state.parsedRequest!.originalInput;
                                _focusNode.requestFocus();
                              },
                              onConfirm: () {
                                HapticFeedback.mediumImpact();
                                context
                                    .read<AIAssistantBloc>()
                                    .add(const ConfirmTrip());
                              },
                            ),

                          // Suggestions
                          if (state.suggestions.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Suggestions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...state.suggestions.map((suggestion) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TripSuggestionCard(
                                  suggestion: suggestion,
                                  onTap: () {
                                    context
                                        .read<AIAssistantBloc>()
                                        .add(ApplySuggestion(suggestion));
                                  },
                                ),
                              );
                            }),
                          ],

                          // Quick examples when idle
                          if (state is AIAssistantIdle &&
                              state.parsedRequest == null)
                            _buildExamples(theme),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Input area
              _buildInputArea(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where would you like to go?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe your trip in natural language, or tap the mic to speak.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildListeningState(AIAssistantListening state, ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          VoiceWaveform(
            volume: _voiceVolume,
            barCount: 7,
            height: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Listening...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (state.partialTranscript.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              state.partialTranscript,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProcessingState(AIAssistantProcessing state, ThemeData theme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Understanding your request...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '"${state.input}"',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildErrorState(AIAssistantError state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamples(ThemeData theme) {
    final examples = [
      'Take me to Kimironko market',
      'I need a moto to Nyabugogo now',
      'Book a cab for tomorrow at 8am',
      'Find me a truck for moving furniture',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try saying...',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        ...examples.map((example) {
          return InkWell(
            onTap: () {
              _textController.text = example;
              _submitText();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '"$example"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Describe your trip...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: _submitText,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitText(),
            ),
          ),

          const SizedBox(width: 12),

          // Voice button
          BlocBuilder<AIAssistantBloc, AIAssistantState>(
            builder: (context, state) {
              final isListening = state is AIAssistantListening;

              return VoiceInputButton(
                isRecording: isListening,
                volume: _voiceVolume,
                size: 56,
                onStart: _startVoice,
                onStop: _stopVoice,
                onCancel: () {
                  context.read<AIAssistantBloc>().add(const CancelVoiceInput());
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
