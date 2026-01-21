import 'package:flutter/material.dart';

/// Badge widget displaying request status
///
/// Shows visual indicator for pending, accepted, denied, expired, cancelled status.
class RequestStatusBadge extends StatelessWidget {
  /// The request status string
  final String status;

  /// Whether to show text label
  final bool showLabel;

  /// Size of the badge
  final double size;

  const RequestStatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getStatusConfig(status);

    if (!showLabel) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: config.color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          config.icon,
          size: size * 0.6,
          color: config.color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 14,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusConfig(
          label: 'Pending',
          icon: Icons.schedule,
          color: Colors.orange,
        );
      case 'accepted':
        return _StatusConfig(
          label: 'Accepted',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case 'denied':
        return _StatusConfig(
          label: 'Denied',
          icon: Icons.cancel,
          color: Colors.red,
        );
      case 'expired':
        return _StatusConfig(
          label: 'Expired',
          icon: Icons.timer_off,
          color: Colors.grey,
        );
      case 'cancelled':
        return _StatusConfig(
          label: 'Cancelled',
          icon: Icons.block,
          color: Colors.grey,
        );
      default:
        return _StatusConfig(
          label: status,
          icon: Icons.help_outline,
          color: Colors.grey,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Animated status badge with pulse effect for pending status
class AnimatedRequestStatusBadge extends StatefulWidget {
  /// The request status string
  final String status;

  /// Whether to animate (only for pending)
  final bool animate;

  const AnimatedRequestStatusBadge({
    super.key,
    required this.status,
    this.animate = true,
  });

  @override
  State<AnimatedRequestStatusBadge> createState() => _AnimatedRequestStatusBadgeState();
}

class _AnimatedRequestStatusBadgeState extends State<AnimatedRequestStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate && widget.status.toLowerCase() == 'pending') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedRequestStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      if (widget.animate && widget.status.toLowerCase() == 'pending') {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animate && widget.status.toLowerCase() == 'pending') {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: RequestStatusBadge(status: widget.status),
      );
    }

    return RequestStatusBadge(status: widget.status);
  }
}
