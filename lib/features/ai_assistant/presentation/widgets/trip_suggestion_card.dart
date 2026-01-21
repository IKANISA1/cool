import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/ai_trip_request.dart';

/// Widget for displaying trip suggestions
class TripSuggestionCard extends StatelessWidget {
  /// The suggestion
  final TripSuggestion suggestion;

  /// Callback when tapped
  final VoidCallback onTap;

  const TripSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForType(suggestion.type),
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion.text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'destination':
        return Icons.location_on;
      case 'time':
        return Icons.schedule;
      case 'vehicle':
        return Icons.directions_car;
      case 'clarification':
        return Icons.help_outline;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

/// Horizontal chip list for quick suggestions
class SuggestionChips extends StatelessWidget {
  /// List of suggestions
  final List<TripSuggestion> suggestions;

  /// Callback when a suggestion is selected
  final ValueChanged<TripSuggestion> onSelect;

  const SuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: suggestions.map((suggestion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestion.text),
              avatar: Icon(
                _getIconForType(suggestion.type),
                size: 16,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onSelect(suggestion);
              },
              backgroundColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'destination':
        return Icons.location_on;
      case 'time':
        return Icons.schedule;
      case 'vehicle':
        return Icons.directions_car;
      default:
        return Icons.lightbulb_outline;
    }
  }
}
