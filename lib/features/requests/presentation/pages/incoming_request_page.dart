import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/ride_request.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';
import '../bloc/request_state.dart';

/// Page for handling incoming ride requests
///
/// Features:
/// - Countdown timer showing remaining time
/// - Sender info with avatar and rating
/// - Accept/Deny buttons
/// - Haptic feedback
class IncomingRequestPage extends StatelessWidget {
  /// The incoming request
  final RideRequest request;

  const IncomingRequestPage({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final sender = request.fromUser;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: BlocListener<RequestBloc, RequestState>(
            listener: (context, state) {
              if (state is RequestAccepted) {
                Navigator.pushReplacementNamed(
                  context,
                  '/request-accepted',
                  arguments: {'request': state.request, 'isSender': false},
                );
              } else if (state is RequestDenied) {
                Navigator.pop(context);
              }
            },
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Title
                Text(
                  'Incoming Request',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Countdown timer
                CountdownTimer(
                  totalSeconds: 60,
                  remainingSeconds: request.secondsRemaining,
                  size: 140,
                  strokeWidth: 10,
                  showUrgencyPulse: true,
                  autoStart: false,
                ),

                const SizedBox(height: 32),

                // Sender info card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GlassmorphicCard(
                    child: Column(
                      children: [
                        // Avatar and name
                        Row(
                          children: [
                            UserAvatar(
                              imageUrl: sender?.avatarUrl,
                              initials: sender?.initials ?? '?',
                              size: 64,
                              isOnline: true,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sender?.name ?? 'Someone',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      RatingStars(
                                        rating: sender?.rating ?? 0,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        (sender?.rating ?? 0).toStringAsFixed(1),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Note (if any)
                        if (request.note != null && request.note!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.format_quote,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    request.note!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    children: [
                      // Deny button
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context
                                  .read<RequestBloc>()
                                  .add(DenyRequest(request.id));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Deny',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Accept button
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              context
                                  .read<RequestBloc>()
                                  .add(AcceptRequest(request.id));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
