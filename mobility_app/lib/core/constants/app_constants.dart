/// App-wide constants
class AppConstants {
  AppConstants._();

  // ═══════════════════════════════════════════════════════════
  // APP INFO
  // ═══════════════════════════════════════════════════════════

  static const String appName = 'Mobility';
  static const String appVersion = '1.0.0';

  // ═══════════════════════════════════════════════════════════
  // TIMEOUTS & DURATIONS
  // ═══════════════════════════════════════════════════════════

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration requestExpiry = Duration(seconds: 60);
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration presenceUpdateInterval = Duration(seconds: 30);

  // ═══════════════════════════════════════════════════════════
  // UI CONSTANTS
  // ═══════════════════════════════════════════════════════════

  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;

  // ═══════════════════════════════════════════════════════════
  // DISCOVERY DEFAULTS
  // ═══════════════════════════════════════════════════════════

  static const double defaultSearchRadiusKm = 10.0;
  static const double maxSearchRadiusKm = 50.0;
  static const double minSearchRadiusKm = 1.0;

  // ═══════════════════════════════════════════════════════════
  // VEHICLE CATEGORIES
  // ═══════════════════════════════════════════════════════════

  static const List<String> vehicleCategories = [
    'moto',
    'cab',
    'liffan',
    'truck',
    'rent',
    'other',
  ];

  // ═══════════════════════════════════════════════════════════
  // USER ROLES
  // ═══════════════════════════════════════════════════════════

  static const List<String> userRoles = [
    'driver',
    'passenger',
    'both',
  ];

  // ═══════════════════════════════════════════════════════════
  // SUPPORTED LANGUAGES
  // ═══════════════════════════════════════════════════════════

  static const List<String> supportedLanguages = [
    'en',  // English
    'fr',  // French
    'sw',  // Swahili
    'rw',  // Kinyarwanda
  ];

  // ═══════════════════════════════════════════════════════════
  // SUPPORTED COUNTRIES (ISO 3166-1 alpha-3)
  // ═══════════════════════════════════════════════════════════

  static const Map<String, String> supportedCountries = {
    'RWA': 'Rwanda',
    'KEN': 'Kenya',
    'UGA': 'Uganda',
    'TZA': 'Tanzania',
    'BDI': 'Burundi',
    'COD': 'DR Congo',
    'NGA': 'Nigeria',
    'GHA': 'Ghana',
    'ZAF': 'South Africa',
  };
}
