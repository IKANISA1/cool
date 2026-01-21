import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/station_marker.dart';

/// Header section showing station name, brand, rating, and address
class StationHeaderSection extends StatelessWidget {
  final StationMarker station;
  final String stationType;

  const StationHeaderSection({
    super.key,
    required this.station,
    required this.stationType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          station.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // Brand/Network
        if (station.brand != null || station.network != null)
          Text(
            station.brand ?? station.network ?? '',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),

        const SizedBox(height: 12),

        // Rating row
        Row(
          children: [
            // Stars
            _buildRatingStars(theme),
            
            const SizedBox(width: 8),
            
            // Rating text
            Text(
              (station.details['rating'] as double? ?? 0).toStringAsFixed(1),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(width: 4),
            
            Text(
              '(${station.details['total_ratings'] ?? 0} reviews)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Address with copy button
        if (station.details['address'] != null)
          InkWell(
            onTap: () => _copyAddress(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.details['address'].toString(),
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (station.details['distance_km'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(station.details['distance_km'] as double).toStringAsFixed(1)} km away',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.copy,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingStars(ThemeData theme) {
    final rating = station.details['rating'] as double? ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: 20, color: Colors.amber.shade600);
        } else if (index < rating) {
          return Icon(Icons.star_half, size: 20, color: Colors.amber.shade600);
        } else {
          return Icon(Icons.star_border, size: 20, color: Colors.amber.shade600);
        }
      }),
    );
  }

  void _copyAddress(BuildContext context) {
    final address = station.details['address']?.toString() ?? '';
    Clipboard.setData(ClipboardData(text: address));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
