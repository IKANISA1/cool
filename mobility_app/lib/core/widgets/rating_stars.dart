import 'package:flutter/material.dart';

/// A star rating display widget
///
/// Features:
/// - Supports half-star ratings
/// - Customizable size and colors
/// - Optional rating text display
class RatingStars extends StatelessWidget {
  /// Rating value (0-5)
  final double rating;

  /// Size of each star
  final double size;

  /// Number of stars to display
  final int starCount;

  /// Color for filled stars
  final Color? filledColor;

  /// Color for empty stars
  final Color? emptyColor;

  /// Whether to show the rating number
  final bool showRatingText;

  /// Spacing between stars
  final double spacing;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.starCount = 5,
    this.filledColor,
    this.emptyColor,
    this.showRatingText = false,
    this.spacing = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = filledColor ?? Colors.amber;
    final empty = emptyColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(starCount, (index) {
          return Padding(
            padding: EdgeInsets.only(right: index < starCount - 1 ? spacing : 0),
            child: _buildStar(index, filled, empty),
          );
        }),
        if (showRatingText) ...[
          SizedBox(width: spacing * 2),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index, Color filled, Color empty) {
    final starValue = index + 1;

    if (rating >= starValue) {
      // Full star
      return Icon(Icons.star_rounded, size: size, color: filled);
    } else if (rating > index && rating < starValue) {
      // Half star
      return Stack(
        children: [
          Icon(Icons.star_rounded, size: size, color: empty),
          ClipRect(
            clipper: _HalfClipper(),
            child: Icon(Icons.star_rounded, size: size, color: filled),
          ),
        ],
      );
    } else {
      // Empty star
      return Icon(Icons.star_rounded, size: size, color: empty);
    }
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// An interactive star rating input widget
class RatingStarsInput extends StatelessWidget {
  /// Current rating value
  final double rating;

  /// Callback when rating changes
  final ValueChanged<double> onRatingChanged;

  /// Size of each star
  final double size;

  /// Number of stars
  final int starCount;

  /// Whether to allow half-star ratings
  final bool allowHalf;

  /// Color for filled stars
  final Color? filledColor;

  /// Color for empty stars
  final Color? emptyColor;

  const RatingStarsInput({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 32,
    this.starCount = 5,
    this.allowHalf = true,
    this.filledColor,
    this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    final filled = filledColor ?? Colors.amber;
    final empty = emptyColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return GestureDetector(
          onTapDown: (details) => _handleTap(index, details),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildStar(index, filled, empty),
          ),
        );
      }),
    );
  }

  void _handleTap(int index, TapDownDetails details) {
    if (allowHalf) {
      // Determine if tap was on left or right half of star
      final isLeftHalf = details.localPosition.dx < size / 2;
      final newRating = isLeftHalf ? index + 0.5 : index + 1.0;
      onRatingChanged(newRating);
    } else {
      onRatingChanged((index + 1).toDouble());
    }
  }

  Widget _buildStar(int index, Color filled, Color empty) {
    final starValue = index + 1;

    if (rating >= starValue) {
      return Icon(Icons.star_rounded, size: size, color: filled);
    } else if (rating > index && rating < starValue) {
      return Stack(
        children: [
          Icon(Icons.star_rounded, size: size, color: empty),
          ClipRect(
            clipper: _HalfClipper(),
            child: Icon(Icons.star_rounded, size: size, color: filled),
          ),
        ],
      );
    } else {
      return Icon(Icons.star_rounded, size: size, color: empty);
    }
  }
}

/// Compact rating display with count
class RatingCompact extends StatelessWidget {
  final double rating;
  final int? reviewCount;

  const RatingCompact({
    super.key,
    required this.rating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (reviewCount != null) ...[
          Text(
            ' ($reviewCount)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
