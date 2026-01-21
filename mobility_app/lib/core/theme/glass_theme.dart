import 'package:flutter/material.dart';

class GlassTheme {
  static const double blurMethods = 20.0;
  static const double blurCard = 15.0;
  
  static final Color glassColorDark = const Color(0xFF1A1A2E).withValues(alpha: 0.6);
  static final Color glassColorLight = Colors.white.withValues(alpha: 0.1);
  
  static final Border glassBorder = Border.all(
    color: Colors.white.withValues(alpha: 0.1),
    width: 1.0,
  );

  static BoxDecoration glassDecoration({
    required BuildContext context,
    double blur = 15,
    double borderRadius = 16,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? glassColorDark : glassColorLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: glassBorder,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          spreadRadius: 2,
        )
      ],
    );
  }
}
