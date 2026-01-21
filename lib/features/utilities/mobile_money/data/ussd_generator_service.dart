import 'package:logging/logging.dart';

import '../domain/country.dart';
import '../domain/mobile_money_network.dart';
import '../domain/mobile_money_repository.dart';

/// Service for generating USSD dial strings
///
/// Provides utilities for creating properly formatted USSD codes
/// for mobile money payments across different providers and countries
class UssdGeneratorService {
  static final _log = Logger('UssdGeneratorService');

  final MobileMoneyRepository _repository;

  UssdGeneratorService(this._repository);

  /// Generate USSD string for a merchant payment
  ///
  /// [phone] - Customer phone number (used to detect country if no countryCode)
  /// [merchantCode] - The merchant code to pay
  /// [amount] - Payment amount
  /// [countryCode] - Optional ISO country code (will detect from phone if not provided)
  /// [networkCode] - Optional network code (will use primary if not provided)
  Future<UssdGenerationResult> generatePaymentUssd({
    required String phone,
    required String merchantCode,
    required double amount,
    String? countryCode,
    String? networkCode,
  }) async {
    try {
      _log.info('Generating USSD for $phone, merchant: $merchantCode, amount: $amount');

      // Step 1: Detect or validate country
      Country country;
      if (countryCode != null) {
        final result = await _repository.getCountryByCode(countryCode);
        final countryOrError = result.fold(
          (error) => null,
          (c) => c,
        );
        if (countryOrError == null) {
          return UssdGenerationResult.error(
            'Invalid country code: $countryCode',
          );
        }
        country = countryOrError;
      } else {
        final result = await _repository.detectCountryFromPhone(phone);
        final countryOrError = result.fold(
          (error) => null,
          (c) => c,
        );
        if (countryOrError == null) {
          return UssdGenerationResult.error(
            'Could not detect country from phone number',
          );
        }
        country = countryOrError;
      }

      // Step 2: Get network (specified or primary)
      MobileMoneyNetwork network;
      if (networkCode != null) {
        final networksResult = await _repository.getNetworksForCountry(
          country.codeAlpha2,
        );
        final networks = networksResult.fold(
          (error) => <MobileMoneyNetwork>[],
          (n) => n,
        );
        final matching = networks.where(
          (n) => n.networkCode == networkCode,
        );
        if (matching.isEmpty) {
          return UssdGenerationResult.error(
            'Network $networkCode not found in ${country.name}',
          );
        }
        network = matching.first;
      } else {
        final result = await _repository.getPrimaryNetwork(country.codeAlpha2);
        final networkOrError = result.fold(
          (error) => null,
          (n) => n,
        );
        if (networkOrError == null) {
          return UssdGenerationResult.error(
            'No mobile money network available in ${country.name}',
          );
        }
        network = networkOrError;
      }

      // Step 3: Generate USSD string
      final ussdResult = await _repository.generateUssdString(
        networkId: network.id,
        merchantCode: merchantCode,
        amount: amount,
        phone: phone,
      );

      return ussdResult.fold(
        (error) => UssdGenerationResult.error(error.message),
        (ussd) => UssdGenerationResult.success(
          ussdString: ussd,
          country: country,
          network: network,
          amount: amount,
          currency: country.currencyCode,
        ),
      );
    } catch (e) {
      _log.severe('USSD generation failed: $e');
      return UssdGenerationResult.error('Failed to generate USSD: $e');
    }
  }

  /// Get all available networks for a phone number's country
  Future<List<MobileMoneyNetwork>> getAvailableNetworks(String phone) async {
    final countryResult = await _repository.detectCountryFromPhone(phone);
    
    return countryResult.fold(
      (error) => [],
      (country) async {
        final networksResult = await _repository.getNetworksForCountry(
          country.codeAlpha2,
        );
        return networksResult.fold(
          (error) => [],
          (networks) => networks,
        );
      },
    );
  }

  /// Validate a phone number for mobile money
  Future<PhoneValidationResult> validatePhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    if (cleaned.length < 8) {
      return PhoneValidationResult.invalid('Phone number too short');
    }

    final countryResult = await _repository.detectCountryFromPhone(cleaned);
    
    return countryResult.fold(
      (error) => PhoneValidationResult.invalid(
        'Phone number not from a supported country',
      ),
      (country) => PhoneValidationResult.valid(
        country: country,
        formattedPhone: country.toInternationalFormat(cleaned),
      ),
    );
  }
}

/// Result of USSD generation
class UssdGenerationResult {
  final bool isSuccess;
  final String? ussdString;
  final Country? country;
  final MobileMoneyNetwork? network;
  final double? amount;
  final String? currency;
  final String? errorMessage;

  const UssdGenerationResult._({
    required this.isSuccess,
    this.ussdString,
    this.country,
    this.network,
    this.amount,
    this.currency,
    this.errorMessage,
  });

  factory UssdGenerationResult.success({
    required String ussdString,
    required Country country,
    required MobileMoneyNetwork network,
    required double amount,
    required String currency,
  }) {
    return UssdGenerationResult._(
      isSuccess: true,
      ussdString: ussdString,
      country: country,
      network: network,
      amount: amount,
      currency: currency,
    );
  }

  factory UssdGenerationResult.error(String message) {
    return UssdGenerationResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  /// Formatted display string (e.g., "MTN MoMo - Rwanda")
  String get displayLabel => 
      isSuccess ? '${network?.shortName} - ${country?.name}' : '';

  /// Formatted amount with currency (e.g., "RF 5,000")
  String get formattedAmount {
    if (!isSuccess || amount == null) return '';
    final formatted = amount!.toStringAsFixed(0);
    return '${country?.currencySymbol ?? currency} $formatted';
  }
}

/// Result of phone validation
class PhoneValidationResult {
  final bool isValid;
  final Country? country;
  final String? formattedPhone;
  final String? errorMessage;

  const PhoneValidationResult._({
    required this.isValid,
    this.country,
    this.formattedPhone,
    this.errorMessage,
  });

  factory PhoneValidationResult.valid({
    required Country country,
    required String formattedPhone,
  }) {
    return PhoneValidationResult._(
      isValid: true,
      country: country,
      formattedPhone: formattedPhone,
    );
  }

  factory PhoneValidationResult.invalid(String message) {
    return PhoneValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }
}
