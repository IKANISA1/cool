import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphic card widget with frosted glass effect
///
/// Features:
/// - Backdrop blur effect
/// - Semi-transparent background
/// - Gradient border
/// - Customizable colors and blur intensity
class GlassmorphicCard extends StatelessWidget {
  /// The child widget to display inside the card
  final Widget child;

  /// Optional callback when the card is tapped
  final VoidCallback? onTap;

  /// Background color (will be made semi-transparent)
  final Color? color;

  /// Border radius of the card
  final double borderRadius;

  /// Blur intensity for the frosted glass effect
  final double blur;

  /// Padding inside the card
  final EdgeInsetsGeometry padding;

  /// Optional margin around the card
  final EdgeInsetsGeometry? margin;

  /// Border width
  final double borderWidth;

  /// Whether to show the gradient border
  final bool showBorder;

  /// Optional width
  final double? width;

  /// Optional height
  final double? height;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius = 16,
    this.blur = 10,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderWidth = 1.5,
    this.showBorder = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.7));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.5);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: showBorder
                      ? Border.all(
                          color: borderColor,
                          width: borderWidth,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A variant of GlassmorphicCard with gradient background
class GradientGlassmorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const GradientGlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradientColors,
    this.borderRadius = 16,
    this.blur = 10,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = gradientColors ??
        [
          theme.colorScheme.primary.withValues(alpha: 0.1),
          theme.colorScheme.secondary.withValues(alpha: 0.1),
        ];

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
