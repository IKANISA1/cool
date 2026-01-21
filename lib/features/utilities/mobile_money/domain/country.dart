import 'package:equatable/equatable.dart';

/// Represents a country with mobile money support
///
/// Contains ISO codes, currency info, and phone prefix for validation
class Country extends Equatable {
  /// Unique identifier
  final String id;

  /// ISO 3166-1 alpha-2 code (e.g., 'RW')
  final String codeAlpha2;

  /// ISO 3166-1 alpha-3 code (e.g., 'RWA')
  final String codeAlpha3;

  /// Full country name
  final String name;

  /// ISO 4217 currency code (e.g., 'RWF')
  final String currencyCode;

  /// Currency symbol (e.g., 'RF')
  final String? currencySymbol;

  /// International phone prefix (e.g., '+250')
  final String phonePrefix;

  /// Whether the country is active for transactions
  final bool isActive;

  const Country({
    required this.id,
    required this.codeAlpha2,
    required this.codeAlpha3,
    required this.name,
    required this.currencyCode,
    this.currencySymbol,
    required this.phonePrefix,
    this.isActive = true,
  });

  /// Creates Country from JSON map (Supabase response)
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String,
      codeAlpha2: json['code_alpha2'] as String,
      codeAlpha3: json['code_alpha3'] as String,
      name: json['name'] as String,
      currencyCode: json['currency_code'] as String,
      currencySymbol: json['currency_symbol'] as String?,
      phonePrefix: json['phone_prefix'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converts to JSON map for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code_alpha2': codeAlpha2,
      'code_alpha3': codeAlpha3,
      'name': name,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'phone_prefix': phonePrefix,
      'is_active': isActive,
    };
  }

  /// Validates if a phone number belongs to this country
  bool matchesPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final withPlus = cleaned.startsWith('+') ? cleaned : '+$cleaned';
    return withPlus.startsWith(phonePrefix);
  }

  /// Formats a local phone number to international format
  String toInternationalFormat(String localPhone) {
    final cleaned = localPhone.replaceAll(RegExp(r'[^0-9]'), '');
    // Remove leading zero if present
    final withoutLeadingZero =
        cleaned.startsWith('0') ? cleaned.substring(1) : cleaned;
    return '$phonePrefix$withoutLeadingZero';
  }

  /// Extracts local number from international format
  String toLocalFormat(String internationalPhone) {
    final cleaned = internationalPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith(phonePrefix)) {
      return '0${cleaned.substring(phonePrefix.length)}';
    }
    return cleaned;
  }

  /// Get flag emoji for country
  String get flagEmoji {
    // Convert country code to flag emoji
    final codePoints = codeAlpha2.toUpperCase().codeUnits.map(
          (code) => code - 0x41 + 0x1F1E6,
        );
    return String.fromCharCodes(codePoints);
  }

  /// Display name with flag
  String get displayNameWithFlag => '$flagEmoji $name';

  @override
  List<Object?> get props => [
        id,
        codeAlpha2,
        codeAlpha3,
        name,
        currencyCode,
        currencySymbol,
        phonePrefix,
        isActive,
      ];

  @override
  String toString() => 'Country($codeAlpha2, $name)';
}
