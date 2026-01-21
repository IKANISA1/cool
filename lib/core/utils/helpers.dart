import 'package:intl/intl.dart';

/// Utility helper functions
class Helpers {
  Helpers._();

  // ═══════════════════════════════════════════════════════════
  // PHONE NUMBER HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Format phone number for display
  static String formatPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Add + prefix if missing
    if (!cleaned.startsWith('+')) {
      return '+$cleaned';
    }
    
    return cleaned;
  }

  /// Mask phone number for privacy (e.g., +250***...789)
  static String maskPhoneNumber(String phone) {
    if (phone.length < 6) return phone;
    
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 3);
    return '$start***$end';
  }

  // ═══════════════════════════════════════════════════════════
  // DATE/TIME HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Format datetime for display
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  /// Format date only
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format time only
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Get relative time string (e.g., "2 min ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins min${mins == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return formatDate(dateTime);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DISTANCE HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Format distance for display
  static String formatDistance(double kilometers) {
    if (kilometers < 1) {
      final meters = (kilometers * 1000).round();
      return '$meters m';
    } else {
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CURRENCY HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Format currency based on country
  static String formatCurrency(double amount, String countryCode) {
    final currencies = {
      'RWA': ('RWF', 'fr_RW'),
      'KEN': ('KES', 'en_KE'),
      'UGA': ('UGX', 'en_UG'),
      'TZA': ('TZS', 'sw_TZ'),
      'NGA': ('NGN', 'en_NG'),
      'ZAF': ('ZAR', 'en_ZA'),
    };

    final currencyInfo = currencies[countryCode] ?? ('USD', 'en_US');
    
    final formatter = NumberFormat.currency(
      locale: currencyInfo.$2,
      symbol: '${currencyInfo.$1} ',
      decimalDigits: 0,
    );

    return formatter.format(amount);
  }

  // ═══════════════════════════════════════════════════════════
  // RATING HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Format rating for display
  static String formatRating(double rating) {
    if (rating == 0) return 'New';
    return rating.toStringAsFixed(1);
  }

  // ═══════════════════════════════════════════════════════════
  // STRING HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // ═══════════════════════════════════════════════════════════
  // VEHICLE CATEGORY HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Get display name for vehicle category
  static String getVehicleCategoryName(String category) {
    const names = {
      'moto': 'Motorcycle',
      'cab': 'Taxi Cab',
      'liffan': 'Liffan',
      'truck': 'Truck',
      'rent': 'Rental',
      'other': 'Other',
    };
    return names[category] ?? capitalize(category);
  }

  /// Get icon name for vehicle category
  static String getVehicleCategoryIcon(String category) {
    const icons = {
      'moto': 'two_wheeler',
      'cab': 'local_taxi',
      'liffan': 'directions_car',
      'truck': 'local_shipping',
      'rent': 'car_rental',
      'other': 'commute',
    };
    return icons[category] ?? 'commute';
  }
}
