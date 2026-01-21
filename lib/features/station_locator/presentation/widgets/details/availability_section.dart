import 'package:flutter/material.dart';

import '../../../data/models/station_marker.dart';

/// Availability section showing visual progress bar for batteries/ports
class AvailabilitySection extends StatelessWidget {
  final StationMarker station;
  final String stationType;

  const AvailabilitySection({
    super.key,
    required this.station,
    required this.stationType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isBatterySwap = stationType == 'battery_swap';
    final available = isBatterySwap
        ? station.details['batteries_available'] as int? ?? 0
        : station.details['available_ports'] as int? ?? 0;
    final total = isBatterySwap
        ? station.details['total_capacity'] as int? ?? 0
        : station.details['total_ports'] as int? ?? 0;
    final percent = total > 0 ? (available / total) : 0.0;
    final color = _getAvailabilityColor(percent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(
              isBatterySwap ? Icons.battery_charging_full : Icons.ev_station,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Availability',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Progress card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Count and percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$available / $total',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        isBatterySwap ? 'batteries available' : 'ports available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(percent * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),

              const SizedBox(height: 12),

              // Visual slots
              _buildSlotIndicators(available, total, color),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotIndicators(int available, int total, Color color) {
    if (total == 0 || total > 12) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(total, (index) {
        final isAvailable = index < available;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isAvailable ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
          child: isAvailable
              ? Icon(
                  stationType == 'battery_swap'
                      ? Icons.battery_full
                      : Icons.electrical_services,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        );
      }),
    );
  }

  Color _getAvailabilityColor(double percent) {
    if (!station.isOperational) return Colors.grey;
    if (percent >= 0.5) return Colors.green;
    if (percent >= 0.25) return Colors.orange;
    return Colors.red;
  }
}
