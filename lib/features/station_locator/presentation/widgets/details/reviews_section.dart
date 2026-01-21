import 'package:flutter/material.dart';

import '../../../domain/entities/station_review.dart';

/// Reviews section with rating summary and review cards
class ReviewsSection extends StatelessWidget {
  final String stationId;
  final String stationType;
  final List<StationReview> reviews;
  final double averageRating;
  final int totalRatings;

  const ReviewsSection({
    super.key,
    required this.stationId,
    required this.stationType,
    required this.reviews,
    required this.averageRating,
    required this.totalRatings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.reviews_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rating summary card
        _buildRatingSummary(theme, colorScheme),

        const SizedBox(height: 16),

        // Review list
        if (reviews.isEmpty)
          _buildEmptyReviews(theme, colorScheme)
        else
          ...reviews.take(3).map((review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReviewCard(review, theme, colorScheme),
          )),

        // See all button
        if (reviews.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Navigate to all reviews page
              },
              child: Text('See all ${reviews.length} reviews'),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSummary(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade100,
            Colors.amber.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  if (index < averageRating.floor()) {
                    return Icon(Icons.star, size: 18, color: Colors.amber.shade700);
                  } else if (index < averageRating) {
                    return Icon(Icons.star_half, size: 18, color: Colors.amber.shade700);
                  } else {
                    return Icon(Icons.star_border, size: 18, color: Colors.amber.shade700);
                  }
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalRatings reviews',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Rating distribution (simplified)
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final percent = _getStarPercent(star);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 6,
                            backgroundColor: Colors.amber.shade200,
                            valueColor: AlwaysStoppedAnimation(Colors.amber.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _getStarPercent(int star) {
    if (reviews.isEmpty) return 0;
    final count = reviews.where((r) => r.rating == star).length;
    return count / reviews.length;
  }

  Widget _buildReviewCard(StationReview review, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                child: Text(
                  (review.userName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      review.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '${review.rating}',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: theme.textTheme.bodyMedium,
            ),
          ],

          // Additional info
          if (review.waitTimeMinutes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Wait time: ${review.waitTimeMinutes} min',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyReviews(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to review this station',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
