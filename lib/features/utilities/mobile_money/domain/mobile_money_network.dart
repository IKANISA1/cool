import 'package:equatable/equatable.dart';

/// Represents a mobile money network/provider
///
/// Each country can have multiple networks (MTN, Airtel, Orange, etc.)
class MobileMoneyNetwork extends Equatable {
  /// Unique identifier
  final String id;

  /// Reference to the country
  final String countryId;

  /// Full network name (e.g., 'MTN Mobile Money')
  final String networkName;

  /// Network code (e.g., 'MTN_MOMO')
  final String networkCode;

  /// Short display name (e.g., 'MTN MoMo')
  final String shortName;

  /// URL to network logo
  final String? logoUrl;

  /// Whether this is the primary network for the country
  final bool isPrimary;

  /// Whether the network is active
  final bool isActive;

  /// Associated USSD dial template (loaded separately)
  final String? dialTemplate;

  const MobileMoneyNetwork({
    required this.id,
    required this.countryId,
    required this.networkName,
    required this.networkCode,
    required this.shortName,
    this.logoUrl,
    this.isPrimary = false,
    this.isActive = true,
    this.dialTemplate,
  });

  /// Creates Network from JSON map (Supabase response)
  factory MobileMoneyNetwork.fromJson(Map<String, dynamic> json) {
    return MobileMoneyNetwork(
      id: json['id'] as String,
      countryId: json['country_id'] as String,
      networkName: json['network_name'] as String,
      networkCode: json['network_code'] as String,
      shortName: json['short_name'] as String,
      logoUrl: json['logo_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      dialTemplate: json['dial_template'] as String?,
    );
  }

  /// Creates Network from RPC function result
  factory MobileMoneyNetwork.fromRpcResult(Map<String, dynamic> json) {
    return MobileMoneyNetwork(
      id: json['network_id'] as String,
      countryId: '', // Not returned from RPC
      networkName: json['network_name'] as String,
      networkCode: json['network_code'] as String,
      shortName: json['short_name'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      dialTemplate: json['dial_template'] as String?,
    );
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country_id': countryId,
      'network_name': networkName,
      'network_code': networkCode,
      'short_name': shortName,
      'logo_url': logoUrl,
      'is_primary': isPrimary,
      'is_active': isActive,
    };
  }

  /// Generate USSD dial string with provided values
  ///
  /// Replaces placeholders in the dial template:
  /// - {MERCHANT} → merchantCode
  /// - {AMOUNT} → amount
  /// - {PHONE} → phone
  String? generateUssdString({
    required String merchantCode,
    required double amount,
    String? phone,
  }) {
    if (dialTemplate == null) return null;

    var result = dialTemplate!;
    result = result.replaceAll('{MERCHANT}', merchantCode);
    result = result.replaceAll('{AMOUNT}', amount.toStringAsFixed(0));
    if (phone != null) {
      result = result.replaceAll('{PHONE}', phone);
    }
    return result;
  }

  /// Copy with new values
  MobileMoneyNetwork copyWith({
    String? id,
    String? countryId,
    String? networkName,
    String? networkCode,
    String? shortName,
    String? logoUrl,
    bool? isPrimary,
    bool? isActive,
    String? dialTemplate,
  }) {
    return MobileMoneyNetwork(
      id: id ?? this.id,
      countryId: countryId ?? this.countryId,
      networkName: networkName ?? this.networkName,
      networkCode: networkCode ?? this.networkCode,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      dialTemplate: dialTemplate ?? this.dialTemplate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        countryId,
        networkName,
        networkCode,
        shortName,
        logoUrl,
        isPrimary,
        isActive,
        dialTemplate,
      ];

  @override
  String toString() => 'MobileMoneyNetwork($shortName, $networkCode)';
}

/// Network type enum for categorization
enum NetworkType {
  mtnMomo('MTN_MOMO', 'MTN Mobile Money'),
  airtelMoney('AIRTEL_MONEY', 'Airtel Money'),
  orangeMoney('ORANGE_MONEY', 'Orange Money'),
  ecoCash('ECOCASH', 'EcoCash'),
  mPesa('MPESA', 'M-Pesa'),
  mvola('MVOLA', 'MVola'),
  tMoney('TMONEY', 'T-Money'),
  moovMoney('MOOV_MONEY', 'Moov Money'),
  dMoney('DMONEY', 'D-Money'),
  mtcMoney('MTC_MONEY', 'MTC Money'),
  getesa('GETESA', 'GETESA');

  final String code;
  final String displayName;

  const NetworkType(this.code, this.displayName);

  /// Get NetworkType from code
  static NetworkType? fromCode(String code) {
    try {
      return NetworkType.values.firstWhere(
        (type) => type.code == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
