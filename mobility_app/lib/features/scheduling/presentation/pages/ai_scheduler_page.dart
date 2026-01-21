import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ridelink/shared/services/gemini_service.dart';
import 'package:ridelink/shared/services/speech_service.dart';

import '../../domain/entities/scheduled_trip.dart';
import '../../domain/repositories/scheduling_repository.dart';
import '../bloc/scheduling_bloc.dart';
import '../bloc/scheduling_event.dart';
import '../bloc/scheduling_state.dart';

/// AI-powered scheduling page using Gemini for natural language parsing
///
/// Users can describe their trip in natural language like:
/// - "I need a ride to Kigali tomorrow at 8am"
/// - "Offering 3 seats from Nyamirambo to Downtown today at 5pm"
/// - "Looking for a car to Musanze next Friday morning"
class AiSchedulerPage extends StatefulWidget {
  const AiSchedulerPage({super.key});

  @override
  State<AiSchedulerPage> createState() => _AiSchedulerPageState();
}

class _AiSchedulerPageState extends State<AiSchedulerPage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _geminiService = GetIt.instance<GeminiService>();
  final _speechService = GetIt.instance<SpeechService>();
  
  bool _isProcessing = false;
  bool _isListening = false;
  bool _speechInitialized = false;
  ScheduleParseResult? _parsedResult;
  String? _errorMessage;
  
  // Animation for mic button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechInitialized = await _speechService.initializeSpeech();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    if (_isListening) _speechService.stopListening();
    super.dispose();
  }

  Future<void> _processInput() async {
    final input = _textController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _parsedResult = null;
    });

    try {
      final result = await _geminiService.parseScheduleRequest(input);
      if (result != null) {
        setState(() {
          _parsedResult = ScheduleParseResult.fromJson(result);
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not understand your request. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to parse your request. Please try again.';
        _isProcessing = false;
      });
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      // Process the input after stopping
      if (_textController.text.isNotEmpty) {
        _processInput();
      }
      return;
    }

    // Check microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice input'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!_speechInitialized) {
      _speechInitialized = await _speechService.initializeSpeech();
    }

    if (!_speechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _errorMessage = null;
      _parsedResult = null;
    });

    await _speechService.startListening(
      onResult: (recognizedWords) {
        if (mounted) {
          setState(() {
            _textController.text = recognizedWords;
          });
        }
      },
      localeId: 'en_US',
    );
  }

  void _confirmTrip() {
    if (_parsedResult == null) return;

    HapticFeedback.mediumImpact();

    context.read<SchedulingBloc>().add(
      CreateTrip(ScheduledTripParams(
        tripType: _parsedResult!.isOffer ? TripType.offer : TripType.request,
        whenDateTime: _parsedResult!.dateTime ?? DateTime.now().add(const Duration(hours: 1)),
        fromText: _parsedResult!.from ?? 'TBD',
        toText: _parsedResult!.to ?? 'TBD',
        seatsQty: _parsedResult!.seats ?? 1,
        vehiclePref: _parsedResult!.vehicleType,
        notes: 'Created via AI: ${_textController.text}',
      )),
    );
  }

  void _retryInput() {
    setState(() {
      _parsedResult = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Schedule'),
      ),
      body: BlocListener<SchedulingBloc, SchedulingState>(
        listener: (context, state) {
          if (state is TripCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trip scheduled successfully!')),
            );
            Navigator.pop(context);
          } else if (state is SchedulingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Describe your trip',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use natural language to schedule a ride. Our AI will understand what you need.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Examples
                _buildExamplesSection(theme),
                const SizedBox(height: 24),

                // Input field with voice button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g., "I need a ride from Kimironko to Downtown tomorrow at 7am"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _processInput(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Voice button
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isListening ? _pulseAnimation.value : 1.0,
                              child: child,
                            );
                          },
                          child: FloatingActionButton(
                            heroTag: 'voice_input',
                            onPressed: _isProcessing ? null : _toggleVoiceInput,
                            backgroundColor: _isListening
                                ? theme.colorScheme.error
                                : theme.colorScheme.primaryContainer,
                            elevation: _isListening ? 8 : 2,
                            child: Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: _isListening
                                  ? Colors.white
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isListening ? 'Listening...' : 'Speak',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _isListening
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Process button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isProcessing ? null : _processInput,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isProcessing ? 'Processing...' : 'Parse with AI'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Result or error
                if (_errorMessage != null)
                  _buildErrorCard(theme)
                else if (_parsedResult != null)
                  Expanded(child: _buildResultCard(theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamplesSection(ThemeData theme) {
    final examples = [
      'Offering 3 seats to Musanze tomorrow 8am',
      'Need a ride from Nyabugogo to KCC today 5pm',
      'Looking for a car to Huye next Friday',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Examples:',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((example) {
            return ActionChip(
              label: Text(
                example,
                style: theme.textTheme.labelSmall,
              ),
              onPressed: () {
                _textController.text = example;
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: _retryInput,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final result = _parsedResult!;

    return SingleChildScrollView(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AI badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI Parsed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _retryInput,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Trip type
              _buildResultRow(
                theme,
                icon: result.isOffer ? Icons.local_offer : Icons.front_hand,
                label: 'Type',
                value: result.isOffer ? 'Offering a ride' : 'Requesting a ride',
                valueColor: result.isOffer ? Colors.green : Colors.orange,
              ),
              const Divider(height: 24),

              // From
              if (result.from != null)
                _buildResultRow(
                  theme,
                  icon: Icons.trip_origin,
                  label: 'From',
                  value: result.from!,
                ),
              if (result.from != null) const Divider(height: 24),

              // To
              if (result.to != null)
                _buildResultRow(
                  theme,
                  icon: Icons.place,
                  label: 'To',
                  value: result.to!,
                ),
              if (result.to != null) const Divider(height: 24),

              // Date/Time
              if (result.dateTime != null)
                _buildResultRow(
                  theme,
                  icon: Icons.schedule,
                  label: 'When',
                  value: DateFormat('EEEE, MMM d at h:mm a').format(result.dateTime!),
                ),
              if (result.dateTime != null) const Divider(height: 24),

              // Seats
              if (result.seats != null)
                _buildResultRow(
                  theme,
                  icon: Icons.person,
                  label: 'Seats',
                  value: '${result.seats}',
                ),
              if (result.seats != null) const Divider(height: 24),

              // Vehicle
              if (result.vehicleType != null)
                _buildResultRow(
                  theme,
                  icon: Icons.directions_car,
                  label: 'Vehicle',
                  value: result.vehicleType!,
                ),

              const SizedBox(height: 24),

              // Confirm button
              BlocBuilder<SchedulingBloc, SchedulingState>(
                builder: (context, state) {
                  final isLoading = state is SchedulingLoading;
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading ? null : _confirmTrip,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm & Schedule',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
