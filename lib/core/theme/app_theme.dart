import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter', // Used Inter as per available fonts
      scaffoldBackgroundColor: const Color(0xFF0F0F1E), // Fixed to match prompt fallback or keeping transparent if handled by Stack
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B4EFF),
        secondary: Color(0xFFFF4E9F),
        surface: Color(0xFF1A1A2E),

      ),
    );
  }
  
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4158D0),
      Color(0xFF7B2CBF),
      Color(0xFFC850C0),
    ],
  );
  
  static const purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
    ],
  );
}
