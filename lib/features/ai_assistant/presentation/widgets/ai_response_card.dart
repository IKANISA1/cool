import 'package:flutter/material.dart';

import '../../../../core/widgets/glassmorphic_card.dart';
import '../../domain/entities/ai_trip_request.dart';

/// Card displaying parsed AI trip response
///
/// Shows extracted trip details with edit capability
class AIResponseCard extends StatelessWidget {
  /// The parsed trip request
  final AITripRequest request;

  /// Callback when edit is tapped
  final VoidCallback? onEdit;

  /// Callback when confirm is tapped
  final VoidCallback? onConfirm;

  const AIResponseCard({
    super.key,
    required this.request,
    this.onEdit,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with confidence indicator
          Row(
            children: [
              Icon(
                request.isValid ? Icons.check_circle : Icons.info_outline,
                color: request.isValid ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.isValid
                      ? 'Trip Details'
                      : 'Needs More Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(request.confidence)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(request.confidence * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getConfidenceColor(request.confidence),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Destination
          if (request.hasDestination)
            _InfoRow(
              icon: Icons.location_on,
              label: 'To',
              value: request.destination!.name,
              subtitle: request.destination!.address,
            ),

          // Origin
          if (request.hasOrigin) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.trip_origin,
              label: 'From',
              value: request.origin!.name,
              subtitle: request.origin!.address,
            ),
          ],

          // Time
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.access_time,
            label: 'When',
            value: _formatTime(request),
          ),

          // Vehicle preference
          if (request.vehiclePreference != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.directions_car,
              label: 'Vehicle',
              value: _formatVehicle(request.vehiclePreference!),
            ),
          ],

          // Passengers
          if (request.passengerCount != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.people,
              label: 'Passengers',
              value: '${request.passengerCount}',
            ),
          ],

          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.note,
              label: 'Notes',
              value: request.notes!,
            ),
          ],

          // Fare Estimate
          if (request.fareEstimate != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.price_change,
              label: 'Estimated Fare',
              value: '${request.fareEstimate!['min']} - ${request.fareEstimate!['max']} ${request.fareEstimate!['currency']}',
              subtitle: 'Approx distance: ${request.fareEstimate!['distance_km']} km',
            ),
          ],

          // Validation errors
          if (request.validationErrors.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: request.validationErrors
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],

          // Actions
          if (onEdit != null || onConfirm != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                if (onEdit != null && onConfirm != null)
                  const SizedBox(width: 12),
                if (onConfirm != null && request.isValid)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Confirm'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(AITripRequest request) {
    switch (request.timeType) {
      case 'now':
        return 'Right now';
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      case 'specific':
        if (request.scheduledTime != null) {
          final time = request.scheduledTime!;
          return '${time.day}/${time.month} at ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
        }
        return 'Scheduled';
      default:
        return 'Immediate';
    }
  }

  String _formatVehicle(String vehicle) {
    switch (vehicle.toLowerCase()) {
      case 'moto':
        return 'Motorcycle';
      case 'cab':
        return 'Taxi / Cab';
      case 'liffan':
        return 'Tuk-Tuk';
      case 'truck':
        return 'Truck';
      case 'any':
        return 'Any available';
      default:
        return vehicle;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
