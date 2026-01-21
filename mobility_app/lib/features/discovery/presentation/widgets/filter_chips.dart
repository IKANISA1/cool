import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/vehicle_icon.dart';

/// Horizontal scrolling filter chips for vehicle types
class FilterChips extends StatelessWidget {
  /// Currently selected vehicle types
  final List<String> selectedTypes;

  /// Callback when a type is toggled
  final ValueChanged<String> onToggle;

  /// Whether to show "All" chip
  final bool showAllChip;

  const FilterChips({
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
            _FilterChipItem(
              label: 'All',
              isSelected: selectedTypes.isEmpty,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle('all');
              },
            ),
            const SizedBox(width: 8),
          ],
          ...vehicleTypes.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChipItem(
                  label: _formatLabel(type),
                  icon: type,
                  isSelected: selectedTypes.contains(type),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(type);
                  },
                ),
              )),
        ],
      ),
    );
  }

  String _formatLabel(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              VehicleIcon(
                category: icon!,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
