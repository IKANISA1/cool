import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Large online/offline toggle switch
///
/// Features:
/// - Prominent visual feedback
/// - Haptic feedback on toggle
/// - Animated state transitions
/// - Glow effect when online
class OnlineToggle extends StatelessWidget {
  /// Current online status
  final bool isOnline;

  /// Callback when toggle is changed
  final ValueChanged<bool> onToggle;

  /// Whether the toggle is loading/disabled
  final bool isLoading;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onToggle(!isOnline);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOnline ? Colors.green : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? Colors.green : Colors.grey,
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                key: ValueKey(isOnline),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Loading indicator
            if (isLoading) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact online/offline toggle for smaller spaces
class OnlineToggleCompact extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const OnlineToggleCompact({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: isOnline,
      onChanged: (value) {
        HapticFeedback.selectionClick();
        onToggle(value);
      },
      activeThumbColor: Colors.green,
      activeTrackColor: Colors.green.withValues(alpha: 0.3),
    );
  }
}
