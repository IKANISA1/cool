import 'package:equatable/equatable.dart';

/// Represents a USSD dial format template
///
/// Contains the dial string template with placeholders for dynamic values
class UssdDialFormat extends Equatable {
  /// Unique identifier
  final String id;

  /// Reference to the network
  final String networkId;

  /// USSD template string with placeholders:
  /// - {MERCHANT}: Merchant code
  /// - {AMOUNT}: Payment amount
  /// - {PHONE}: Phone number (for P2P)
  final String dialTemplate;

  /// Type of operation this format is for
  final UssdFormatType formatType;

  /// Human-readable description
  final String? description;

  /// Whether this format is active
  final bool isActive;

  const UssdDialFormat({
    required this.id,
    required this.networkId,
    required this.dialTemplate,
    this.formatType = UssdFormatType.merchantPayment,
    this.description,
    this.isActive = true,
  });

  /// Creates UssdDialFormat from JSON map (Supabase response)
  factory UssdDialFormat.fromJson(Map<String, dynamic> json) {
    return UssdDialFormat(
      id: json['id'] as String,
      networkId: json['network_id'] as String,
      dialTemplate: json['dial_template'] as String,
      formatType: UssdFormatType.fromString(
        json['format_type'] as String? ?? 'merchant_payment',
      ),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converts to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'network_id': networkId,
      'dial_template': dialTemplate,
      'format_type': formatType.value,
      'description': description,
      'is_active': isActive,
    };
  }

  /// Generate actual dial string by replacing placeholders
  ///
  /// Returns the USSD string ready to be dialed
  String generate({
    String? merchantCode,
    double? amount,
    String? phone,
  }) {
    var result = dialTemplate;

    if (merchantCode != null) {
      result = result.replaceAll('{MERCHANT}', merchantCode);
    }
    if (amount != null) {
      // Format amount without decimals for USSD
      result = result.replaceAll('{AMOUNT}', amount.toStringAsFixed(0));
    }
    if (phone != null) {
      // Clean phone number for USSD
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      result = result.replaceAll('{PHONE}', cleanPhone);
    }

    return result;
  }

  /// Check if this format requires a merchant code
  bool get requiresMerchant => dialTemplate.contains('{MERCHANT}');

  /// Check if this format requires a phone number
  bool get requiresPhone => dialTemplate.contains('{PHONE}');

  /// Check if this format requires an amount
  bool get requiresAmount => dialTemplate.contains('{AMOUNT}');

  /// Get list of required placeholders
  List<UssdPlaceholder> get requiredPlaceholders {
    final placeholders = <UssdPlaceholder>[];
    if (requiresMerchant) placeholders.add(UssdPlaceholder.merchant);
    if (requiresAmount) placeholders.add(UssdPlaceholder.amount);
    if (requiresPhone) placeholders.add(UssdPlaceholder.phone);
    return placeholders;
  }

  @override
  List<Object?> get props => [
        id,
        networkId,
        dialTemplate,
        formatType,
        description,
        isActive,
      ];

  @override
  String toString() => 'UssdDialFormat($formatType: $dialTemplate)';
}

/// Type of USSD operation
enum UssdFormatType {
  merchantPayment('merchant_payment', 'Merchant Payment'),
  p2pTransfer('p2p_transfer', 'Person to Person'),
  balanceCheck('balance_check', 'Balance Check'),
  withdrawal('withdrawal', 'Cash Withdrawal');

  final String value;
  final String displayName;

  const UssdFormatType(this.value, this.displayName);

  /// Parse from database string value
  static UssdFormatType fromString(String value) {
    switch (value) {
      case 'merchant_payment':
        return UssdFormatType.merchantPayment;
      case 'p2p_transfer':
        return UssdFormatType.p2pTransfer;
      case 'balance_check':
        return UssdFormatType.balanceCheck;
      case 'withdrawal':
        return UssdFormatType.withdrawal;
      default:
        return UssdFormatType.merchantPayment;
    }
  }
}

/// Placeholders used in USSD templates
enum UssdPlaceholder {
  merchant('MERCHANT', 'Merchant Code'),
  amount('AMOUNT', 'Payment Amount'),
  phone('PHONE', 'Phone Number');

  final String placeholder;
  final String displayName;

  const UssdPlaceholder(this.placeholder, this.displayName);
}
