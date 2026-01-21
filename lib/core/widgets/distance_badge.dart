import 'package:flutter/material.dart';

/// A badge showing distance in km with visual styling
///
/// Automatically formats distance:
/// - < 1 km: shows in meters (e.g., "500m")
/// - >= 1 km: shows in km with 1 decimal (e.g., "2.5 km")
class DistanceBadge extends StatelessWidget {
  /// Distance in kilometers
  final double distanceKm;

  /// Size variant: 'small', 'medium', 'large'
  final String size;

  /// Whether to show the location icon
  final bool showIcon;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom text color
  final Color? textColor;

  const DistanceBadge({
    super.key,
    required this.distanceKm,
    this.size = 'medium',
    this.showIcon = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.secondaryContainer;
    final txtColor = textColor ?? theme.colorScheme.onSecondaryContainer;

    final (padding, iconSize, fontSize) = _getSizeParams();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.near_me,
              size: iconSize,
              color: txtColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatDistance(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }

  (EdgeInsets, double, double) _getSizeParams() {
    switch (size) {
      case 'small':
        return (
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          12.0,
          10.0
        );
      case 'large':
        return (
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          18.0,
          14.0
        );
      case 'medium':
      default:
        return (
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          14.0,
          12.0
        );
    }
  }

  String _formatDistance() {
    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '${meters}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }
}

/// A widget showing distance with walking/driving time estimate
class DistanceWithTime extends StatelessWidget {
  final double distanceKm;
  final String mode; // 'walk', 'drive', 'bike'

  const DistanceWithTime({
    super.key,
    required this.distanceKm,
    this.mode = 'drive',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DistanceBadge(distanceKm: distanceKm),
        const SizedBox(width: 8),
        Icon(
          _getModeIcon(),
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          _estimateTime(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getModeIcon() {
    switch (mode) {
      case 'walk':
        return Icons.directions_walk;
      case 'bike':
        return Icons.directions_bike;
      case 'drive':
      default:
        return Icons.directions_car;
    }
  }

  String _estimateTime() {
    // Average speeds in km/h
    final speed = switch (mode) {
      'walk' => 5.0,
      'bike' => 15.0,
      'drive' => 30.0, // Urban average
      _ => 30.0,
    };

    final minutes = (distanceKm / speed * 60).round();

    if (minutes < 1) {
      return '< 1 min';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (remainingMins == 0) {
        return '$hours hr';
      }
      return '$hours hr $remainingMins min';
    }
  }
}
