import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ridelink/core/error/exceptions.dart';

/// Environment configuration loader
/// 
/// Loads environment variables from .env file and provides
/// typed access to all configuration values.
class EnvConfig {
  EnvConfig._();

  /// Initialize the environment configuration
  /// Call this before runApp()
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    _validateRequiredKeys();
  }

  /// Validate that all required keys are present
  static void _validateRequiredKeys() {
    const requiredKeys = [
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
      'GEMINI_API_KEY',
    ];

    final missingKeys = <String>[];
    for (final key in requiredKeys) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      throw ConfigurationException(
        message: 'Missing required environment variables',
        missingKeys: missingKeys,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ENVIRONMENT
  // ═══════════════════════════════════════════════════════════

  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // ═══════════════════════════════════════════════════════════
  // SUPABASE
  // ═══════════════════════════════════════════════════════════

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  // ═══════════════════════════════════════════════════════════
  // GEMINI AI
  // ═══════════════════════════════════════════════════════════

  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY']!;

  // ═══════════════════════════════════════════════════════════
  // GOOGLE MAPS (Optional)
  // ═══════════════════════════════════════════════════════════

  static String? get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'];

  // ═══════════════════════════════════════════════════════════
  // MOBILE MONEY (Optional)
  // ═══════════════════════════════════════════════════════════

  static String? get mtnMomoApiKey => dotenv.env['MTN_MOMO_API_KEY'];
  static String? get mtnMomoPrimaryKey => dotenv.env['MTN_MOMO_PRIMARY_KEY'];
  static String get mtnMomoEnvironment => 
      dotenv.env['MTN_MOMO_ENVIRONMENT'] ?? 'sandbox';
}
