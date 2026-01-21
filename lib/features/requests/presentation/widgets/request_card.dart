import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/countdown_timer.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/ride_request.dart';
import 'request_status_badge.dart';

/// Card widget for displaying ride request (incoming or outgoing)
///
/// Shows sender/recipient info, status, countdown (if pending),
/// and appropriate action buttons.
class RequestCard extends StatelessWidget {
  /// The ride request
  final RideRequest request;

  /// Whether this is an outgoing request (true) or incoming (false)
  final bool isOutgoing;

  /// Callback when accept is tapped (for incoming requests)
  final VoidCallback? onAccept;

  /// Callback when deny is tapped (for incoming requests)
  final VoidCallback? onDeny;

  /// Callback when cancel is tapped (for outgoing requests)
  final VoidCallback? onCancel;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether to show the countdown timer
  final bool showCountdown;

  const RequestCard({
    super.key,
    required this.request,
    required this.isOutgoing,
    this.onAccept,
    this.onDeny,
    this.onCancel,
    this.onTap,
    this.showCountdown = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = isOutgoing ? request.toUser : request.fromUser;

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with user info and status
            Row(
              children: [
                // User avatar
                UserAvatar(
                  imageUrl: user?.avatarUrl,
                  initials: user?.initials ?? '?',
                  size: 48,
                  isOnline: request.isPending,
                ),

                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOutgoing ? 'Request sent' : 'Incoming request',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge or countdown
                if (request.isPending && showCountdown)
                  CountdownTimer(
                    totalSeconds: 60,
                    remainingSeconds: request.secondsRemaining,
                    size: 44,
                    strokeWidth: 4,
                    autoStart: false,
                  )
                else
                  RequestStatusBadge(status: request.status),
              ],
            ),

            // Note (if present)
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (only for pending requests)
            if (request.isPending) ...[
              const SizedBox(height: 16),
              if (isOutgoing)
                // Cancel button for outgoing
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Cancel Request'),
                  ),
                )
              else
                // Accept/Deny for incoming
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onDeny?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                        ),
                        child: const Text('Deny'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          onAccept?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for RequestCard
class RequestCardShimmer extends StatelessWidget {
  const RequestCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar shimmer
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
