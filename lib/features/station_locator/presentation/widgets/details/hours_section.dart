import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/station_marker.dart';

/// Hours section showing operating schedule
class HoursSection extends StatelessWidget {
  final StationMarker station;

  const HoursSection({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final is24Hours = station.details['is_24_hours'] as bool? ?? false;
    final operatingHours = station.details['operating_hours'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.schedule, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Operating Hours',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (is24Hours)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_filled, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '24 Hours',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Hours card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: is24Hours
              ? _build24HoursContent(theme, colorScheme)
              : _buildScheduleContent(theme, colorScheme, operatingHours),
        ),
      ],
    );
  }

  Widget _build24HoursContent(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.access_time_filled, color: Colors.green.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open 24 Hours',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Available anytime, every day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleContent(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic>? hours) {
    final defaultHours = {
      'monday': '06:00 - 22:00',
      'tuesday': '06:00 - 22:00',
      'wednesday': '06:00 - 22:00',
      'thursday': '06:00 - 22:00',
      'friday': '06:00 - 22:00',
      'saturday': '07:00 - 20:00',
      'sunday': '08:00 - 18:00',
    };

    final schedule = hours ?? defaultHours;
    final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

    return Column(
      children: schedule.entries.map((entry) {
        final isToday = entry.key.toLowerCase() == today;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  _capitalizeFirst(entry.key),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isToday ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: isToday ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
