import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../domain/entities/ride_request.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';
import '../bloc/request_state.dart';

/// Page showing countdown while waiting for request response
class RequestWaitingPage extends StatefulWidget {
  /// The sent request
  final RideRequest request;

  const RequestWaitingPage({
    super.key,
    required this.request,
  });

  @override
  State<RequestWaitingPage> createState() => _RequestWaitingPageState();
}

class _RequestWaitingPageState extends State<RequestWaitingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _cancelRequest() {
    HapticFeedback.mediumImpact();
    context.read<RequestBloc>().add(CancelRequest(widget.request.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<RequestBloc, RequestState>(
            listener: (context, state) {
              if (state is RequestAccepted) {
                HapticFeedback.heavyImpact();
                Navigator.pushReplacementNamed(
                  context,
                  '/request-accepted',
                  arguments: state.request,
                );
              } else if (state is RequestDenied) {
                HapticFeedback.lightImpact();
                _showDeniedDialog();
              } else if (state is RequestExpired) {
                HapticFeedback.lightImpact();
                _showExpiredDialog();
              }
            },
            builder: (context, state) {
              final secondsRemaining = state is RequestSent
                  ? state.secondsRemaining
                  : widget.request.secondsRemaining;

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _cancelRequest,
                          icon: const Icon(Icons.close),
                        ),
                        const Spacer(),
                        Text(
                          'Waiting for Response',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Countdown timer
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.05,
                        child: CountdownTimer(
                          totalSeconds: 60,
                          remainingSeconds: secondsRemaining,
                          size: 180,
                          strokeWidth: 12,
                          autoStart: false,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Status text
                  Text(
                    'Request sent!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Waiting for ${widget.request.toUser?.name ?? 'the user'} to respond...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Request note (if any)
                  if (widget.request.note != null &&
                      widget.request.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: GlassmorphicCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.message,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.request.note!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Cancel button
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _cancelRequest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Request Denied'),
        content: const Text(
          'The user has declined your request. You can try sending to someone else.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to discovery
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Request Expired'),
        content: const Text(
          'The request timed out without a response. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to discovery
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
