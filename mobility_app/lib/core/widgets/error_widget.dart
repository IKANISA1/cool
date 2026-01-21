import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/asset_constants.dart';
import 'custom_button.dart';

/// Error widget with retry option
class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final bool showAnimation;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.showAnimation = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAnimation)
              Lottie.asset(
                AssetConstants.errorAnimation,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon ?? Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  );
                },
              )
            else
              Icon(
                icon ?? Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: retryText,
                onPressed: onRetry,
                icon: Icons.refresh,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onAction;
  final String? actionText;
  final IconData? actionIcon;
  final bool showAnimation;
  final IconData? icon;

  const EmptyStateWidget({
    super.key,
    this.title,
    required this.message,
    this.onAction,
    this.actionText,
    this.actionIcon,
    this.showAnimation = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAnimation)
              Lottie.asset(
                AssetConstants.emptyAnimation,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon ?? Icons.inbox_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  );
                },
              )
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: actionText!,
                onPressed: onAction,
                icon: actionIcon,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      title: 'No Internet Connection',
      message: 'Please check your network connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

/// Permission required widget
class PermissionRequiredWidget extends StatelessWidget {
  final String permission;
  final String description;
  final VoidCallback? onRequestPermission;

  const PermissionRequiredWidget({
    super.key,
    required this.permission,
    required this.description,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$permission Required',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRequestPermission != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Grant $permission',
                onPressed: onRequestPermission,
                icon: Icons.check_circle_outline,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
