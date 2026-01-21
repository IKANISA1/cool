import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/station_marker.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

/// Card widget for displaying a single station with swipe actions
class StationListCard extends StatelessWidget {
  final StationMarker station;
  final String stationType;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onNavigateTap;

  const StationListCard({
    super.key,
    required this.station,
    required this.stationType,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.onNavigateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(station.id),
      background: _buildSwipeBackground(theme, isLeft: false),
      secondaryBackground: _buildSwipeBackground(theme, isLeft: true),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Navigate action (swipe left)
          HapticFeedback.mediumImpact();
          onNavigateTap();
          return false;
        } else {
          // Favorite action (swipe right)
          HapticFeedback.lightImpact();
          onFavoriteTap();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: onFavoriteTap,
              ),
            ),
          );
          return false;
        }
      },
      child: GlassmorphicCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Station icon/indicator
                _buildStationIcon(theme),
                
                const SizedBox(width: 12),
                
                // Station info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              station.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Favorite button
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              onFavoriteTap();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      
                      // Brand/Network
                      if (_getBrandOrNetwork() != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _getBrandOrNetwork()!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      // Address
                      if (station.details['address'] != null)
                        Text(
                          station.details['address'].toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                // Distance (if available)
                if (station.details['distance_km'] != null)
                  _buildStatChip(
                    icon: Icons.location_on,
                    label: '${(station.details['distance_km'] as double).toStringAsFixed(1)} km',
                    theme: theme,
                  ),
                
                if (station.details['distance_km'] != null)
                  const SizedBox(width: 8),
                
                // Rating
                if ((station.details['rating'] as double?) != null && 
                    (station.details['rating'] as double) > 0)
                  _buildStatChip(
                    icon: Icons.star,
                    label: (station.details['rating'] as double).toStringAsFixed(1),
                    theme: theme,
                    color: Colors.amber,
                  ),
                
                if ((station.details['rating'] as double?) != null)
                  const SizedBox(width: 8),
                
                // Availability
                _buildAvailabilityChip(theme),
                
                const Spacer(),
                
                // Navigate button
                IconButton(
                  icon: const Icon(Icons.directions),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onNavigateTap();
                  },
                  color: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Additional info based on type
            if (stationType == 'battery_swap')
              _buildBatterySwapInfo(theme)
            else
              _buildEVChargingInfo(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStationIcon(ThemeData theme) {
    final color = _getAvailabilityColor();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        stationType == 'battery_swap' 
            ? Icons.battery_charging_full 
            : Icons.ev_station,
        color: color,
        size: 32,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? theme.colorScheme.onSurface),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(ThemeData theme) {
    final color = _getAvailabilityColor();
    final text = _getAvailabilityText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatterySwapInfo(ThemeData theme) {
    final available = station.details['batteries_available'] as int? ?? 0;
    final total = station.details['total_capacity'] as int? ?? 0;
    final price = station.details['price_per_swap'];
    final currency = station.details['currency'] ?? 'RWF';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_charging_full,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$available / $total batteries',
            style: theme.textTheme.bodySmall,
          ),
          
          if (price != null) ...[
            const Spacer(),
            Text(
              '$price $currency',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEVChargingInfo(ThemeData theme) {
    final available = station.details['available_ports'] as int? ?? 0;
    final total = station.details['total_ports'] as int? ?? 0;
    final maxPower = station.details['max_power_kw'] as int?;
    final connectorTypes = station.details['connector_types'] as List?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.ev_station,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$available / $total ports',
            style: theme.textTheme.bodySmall,
          ),
          
          if (maxPower != null) ...[
            const SizedBox(width: 12),
            Icon(Icons.bolt, size: 16, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(
              'Up to ${maxPower}kW',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          
          if (connectorTypes != null && connectorTypes.isNotEmpty) ...[
            const Spacer(),
            Text(
              '${connectorTypes.length} types',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(ThemeData theme, {required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLeft ? Colors.blue : Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isLeft ? Icons.directions : Icons.favorite,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  String? _getBrandOrNetwork() {
    if (stationType == 'battery_swap') {
      return station.brand;
    } else {
      return station.network;
    }
  }

  Color _getAvailabilityColor() {
    if (!station.isOperational) return Colors.grey;

    final available = station.isBatterySwap
        ? station.details['batteries_available'] as int? ?? 0
        : station.details['available_ports'] as int? ?? 0;
    final total = station.isBatterySwap
        ? station.details['total_capacity'] as int? ?? 1
        : station.details['total_ports'] as int? ?? 1;

    final percent = total > 0 ? (available / total) * 100 : 0;

    if (percent >= 50) return Colors.green;
    if (percent >= 25) return Colors.orange;
    return Colors.red;
  }

  String _getAvailabilityText() {
    if (!station.isOperational) return 'Closed';

    final available = station.isBatterySwap
        ? station.details['batteries_available'] as int? ?? 0
        : station.details['available_ports'] as int? ?? 0;
    final total = station.isBatterySwap
        ? station.details['total_capacity'] as int? ?? 1
        : station.details['total_ports'] as int? ?? 1;

    final percent = total > 0 ? (available / total) * 100 : 0;

    if (percent >= 75) return 'High';
    if (percent >= 50) return 'Medium';
    if (percent >= 25) return 'Low';
    return 'Very Low';
  }
}
