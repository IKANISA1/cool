import 'package:flutter/material.dart';

import '../../../data/models/station_marker.dart';

/// Amenities section showing icon grid
class AmenitiesSection extends StatelessWidget {
  final StationMarker station;

  const AmenitiesSection({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amenities = station.details['amenities'] as List? ?? [];

    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.local_convenience_store, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Amenities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Amenities grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: amenities.map<Widget>((amenity) {
              return _buildAmenityItem(amenity.toString(), theme, colorScheme);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityItem(String amenity, ThemeData theme, ColorScheme colorScheme) {
    final config = _getAmenityConfig(amenity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: config['color'] as Color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            config['icon'] as IconData,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          config['label'] as String,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getAmenityConfig(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return {
          'icon': Icons.wifi,
          'label': 'WiFi',
          'color': Colors.blue,
        };
      case 'restroom':
      case 'toilet':
        return {
          'icon': Icons.wc,
          'label': 'Restroom',
          'color': Colors.teal,
        };
      case 'food':
      case 'restaurant':
        return {
          'icon': Icons.restaurant,
          'label': 'Food',
          'color': Colors.orange,
        };
      case 'coffee':
      case 'cafe':
        return {
          'icon': Icons.coffee,
          'label': 'Coffee',
          'color': Colors.brown,
        };
      case 'parking':
        return {
          'icon': Icons.local_parking,
          'label': 'Parking',
          'color': Colors.indigo,
        };
      case 'shelter':
      case 'covered':
        return {
          'icon': Icons.roofing,
          'label': 'Covered',
          'color': Colors.grey.shade700,
        };
      case 'security':
        return {
          'icon': Icons.security,
          'label': 'Security',
          'color': Colors.green,
        };
      case 'waiting_area':
      case 'lounge':
        return {
          'icon': Icons.weekend,
          'label': 'Lounge',
          'color': Colors.purple,
        };
      case 'shop':
      case 'store':
        return {
          'icon': Icons.store,
          'label': 'Shop',
          'color': Colors.pink,
        };
      case 'atm':
        return {
          'icon': Icons.atm,
          'label': 'ATM',
          'color': Colors.green.shade700,
        };
      default:
        return {
          'icon': Icons.check_circle,
          'label': _capitalizeFirst(amenity),
          'color': Colors.grey,
        };
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }
}
