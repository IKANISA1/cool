import 'package:flutter/material.dart';

/// Vehicle category icon widget
///
/// Displays an appropriate icon for each vehicle category:
/// - moto: motorcycle
/// - cab: car/taxi
/// - liffan: three-wheeler/tuk-tuk
/// - truck: cargo truck
/// - rent: rental car
/// - other: generic vehicle
class VehicleIcon extends StatelessWidget {
  /// The vehicle category
  final String category;

  /// Size of the icon
  final double size;

  /// Icon color (uses theme primary if not specified)
  final Color? color;

  /// Whether to show in a circular container
  final bool showBackground;

  /// Background color for the container
  final Color? backgroundColor;

  const VehicleIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
    this.showBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;

    final icon = _getIconForCategory(category.toLowerCase());

    if (showBackground) {
      return Container(
        width: size * 1.8,
        height: size * 1.8,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.4),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: size,
          color: iconColor,
        ),
      );
    }

    return Icon(
      icon,
      size: size,
      color: iconColor,
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'moto':
        return Icons.two_wheeler;
      case 'cab':
        return Icons.local_taxi;
      case 'liffan':
        return Icons.electric_rickshaw;
      case 'truck':
        return Icons.local_shipping;
      case 'rent':
        return Icons.car_rental;
      case 'other':
      default:
        return Icons.directions_car;
    }
  }
}

/// A row of vehicle type chips for filtering
class VehicleTypeChips extends StatelessWidget {
  /// Currently selected vehicle types
  final List<String> selectedTypes;

  /// Callback when a type is toggled
  final Function(String) onToggle;

  /// Whether to show "All" chip
  final bool showAllChip;

  const VehicleTypeChips({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
    this.showAllChip = true,
  });

  static const List<String> vehicleTypes = [
    'moto',
    'cab',
    'liffan',
    'truck',
    'rent',
    'other',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showAllChip) ...[
            _buildChip(context, 'All', selectedTypes.isEmpty),
            const SizedBox(width: 8),
          ],
          ...vehicleTypes.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  context,
                  type,
                  selectedTypes.contains(type),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String type, bool isSelected) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type != 'All') ...[
            VehicleIcon(
              category: type,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
          ],
          Text(_formatLabel(type)),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onToggle(type),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  String _formatLabel(String type) {
    if (type == 'All') return type;
    return type[0].toUpperCase() + type.substring(1);
  }
}

/// Badge showing vehicle category with icon and label
class VehicleBadge extends StatelessWidget {
  final String category;
  final int? capacity;

  const VehicleBadge({
    super.key,
    required this.category,
    this.capacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VehicleIcon(
            category: category,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatLabel(category),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.primary,
            ),
          ),
          if (capacity != null) ...[
            const SizedBox(width: 4),
            Text(
              '• $capacity',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLabel(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}
