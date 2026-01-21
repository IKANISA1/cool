import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/station_marker.dart';
import '../../domain/entities/station_review.dart';
import '../widgets/details/station_header_section.dart';
import '../widgets/details/availability_section.dart';
import '../widgets/details/pricing_section.dart';
import '../widgets/details/hours_section.dart';
import '../widgets/details/amenities_section.dart';
import '../widgets/details/reviews_section.dart';

/// Full details page for a station
class StationDetailsPage extends StatelessWidget {
  final StationMarker station;
  final String stationType;

  const StationDetailsPage({
    super.key,
    required this.station,
    required this.stationType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero app bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share),
                ),
                onPressed: () => _shareStation(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroBackground(theme),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  StationHeaderSection(
                    station: station,
                    stationType: stationType,
                  ),

                  const SizedBox(height: 24),

                  // Availability section
                  AvailabilitySection(
                    station: station,
                    stationType: stationType,
                  ),

                  const SizedBox(height: 24),

                  // Pricing section
                  PricingSection(
                    station: station,
                    stationType: stationType,
                  ),

                  const SizedBox(height: 24),

                  // Hours section
                  HoursSection(
                    station: station,
                  ),

                  const SizedBox(height: 24),

                  // Amenities section
                  if (_hasAmenities())
                    Column(
                      children: [
                        AmenitiesSection(
                          station: station,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Reviews section
                  ReviewsSection(
                    stationId: station.id,
                    stationType: stationType,
                    reviews: _getMockReviews(),
                    averageRating: station.details['rating'] as double? ?? 0,
                    totalRatings: station.details['total_ratings'] as int? ?? 0,
                  ),

                  // Bottom padding for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToStation(context),
        icon: const Icon(Icons.directions),
        label: const Text('Navigate'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeroBackground(ThemeData theme) {
    final isBatterySwap = stationType == 'battery_swap';
    final availabilityColor = _getAvailabilityColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            availabilityColor.withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: GridPaper(
                color: theme.colorScheme.onSurface,
                interval: 50,
                divisions: 2,
                subdivisions: 1,
              ),
            ),
          ),
          
          // Center icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: availabilityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isBatterySwap ? Icons.battery_charging_full : Icons.ev_station,
                size: 60,
                color: availabilityColor,
              ),
            ),
          ),

          // Status badge
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: station.isOperational ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    station.isOperational ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    station.isOperational ? 'Open' : 'Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  bool _hasAmenities() {
    final amenities = station.details['amenities'] as List?;
    return amenities != null && amenities.isNotEmpty;
  }

  List<StationReview> _getMockReviews() {
    return [
      StationReview(
        id: '1',
        userId: 'user1',
        stationType: stationType,
        stationId: station.id,
        rating: 5,
        comment: 'Great service! Quick swap and friendly staff.',
        serviceQuality: 5,
        waitTimeMinutes: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        userName: 'Jean P.',
      ),
      StationReview(
        id: '2',
        userId: 'user2',
        stationType: stationType,
        stationId: station.id,
        rating: 4,
        comment: 'Good location but can get busy during rush hours.',
        serviceQuality: 4,
        waitTimeMinutes: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        userName: 'Marie K.',
      ),
      StationReview(
        id: '3',
        userId: 'user3',
        stationType: stationType,
        stationId: station.id,
        rating: 5,
        comment: 'Clean facility and reliable batteries.',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        userName: 'David M.',
      ),
    ];
  }

  void _shareStation(BuildContext context) {
    HapticFeedback.mediumImpact();
    final shareText = '${station.name}\n${station.details['address'] ?? ''}\nhttps://maps.google.com/?q=${station.position.latitude},${station.position.longitude}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: $shareText')),
    );
  }

  Future<void> _navigateToStation(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.position.latitude},${station.position.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }
}
