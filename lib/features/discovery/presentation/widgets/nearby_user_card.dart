import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/distance_badge.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/vehicle_icon.dart';
import '../../domain/entities/nearby_user.dart';

/// Card displaying a nearby user with their profile and vehicle info
///
/// Features:
/// - User avatar with online indicator
/// - Name, rating, and verification badge
/// - Vehicle info for drivers
/// - Distance badge
/// - Request button
class NearbyUserCard extends StatelessWidget {
  /// The user to display
  final NearbyUser user;

  /// Callback when request button is tapped
  final VoidCallback onRequestTap;

  /// Callback when card is tapped (view profile)
  final VoidCallback? onTap;

  const NearbyUserCard({
    super.key,
    required this.user,
    required this.onRequestTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Avatar, name, distance
          Row(
            children: [
              // Avatar with online indicator
              UserAvatar(
                imageUrl: user.avatarUrl,
                initials: user.initials,
                size: 56,
                isOnline: user.isOnline,
              ),

              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and verification
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.verified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    Row(
                      children: [
                        RatingStars(
                          rating: user.rating,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Distance badge
              DistanceBadge(
                distanceKm: user.distanceKm,
                size: 'medium',
              ),
            ],
          ),

          // Vehicle info (for drivers)
          if (user.vehicleCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  VehicleIcon(
                    category: user.vehicleCategory!,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatVehicleCategory(user.vehicleCategory!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (user.vehicleCapacity != null)
                          Text(
                            '${user.vehicleCapacity} seats',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (user.vehicleDescription != null)
                    Text(
                      user.vehicleDescription!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Request button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onRequestTap();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Send Request',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVehicleCategory(String category) {
    switch (category.toLowerCase()) {
      case 'moto':
        return 'Motorcycle';
      case 'cab':
        return 'Taxi/Cab';
      case 'liffan':
        return 'Tuk-Tuk';
      case 'truck':
        return 'Truck';
      case 'rent':
        return 'Rental Car';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }
}

/// Shimmer loading placeholder for NearbyUserCard
class NearbyUserCardShimmer extends StatelessWidget {
  const NearbyUserCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerColor = theme.colorScheme.surfaceContainerHighest;

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar shimmer
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Text shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 140,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              // Distance shimmer
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Vehicle info shimmer
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 14),

          // Button shimmer
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
