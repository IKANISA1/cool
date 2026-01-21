import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'domain/country.dart';
import 'domain/mobile_money_network.dart';
import 'domain/mobile_money_repository.dart';

/// Mobile money service for payment integrations
///
/// Supports multiple providers common in Sub-Saharan Africa across 28 countries:
/// - MTN Mobile Money (MoMo) - Ghana, Rwanda, Cameroon, Zambia, Benin, Congo
/// - Airtel Money - Seychelles, Malawi, Chad, Niger, Gabon
/// - Orange Money - Burkina Faso, CAR, Cote d'Ivoire, DR Congo, Guinea, Senegal
/// - Vodacom M-Pesa - Tanzania
/// - Econet EcoCash - Zimbabwe, Burundi
/// - Telma MVola - Madagascar, Comoros
/// - T-Money - Togo
/// - Moov Money - Mauritania
/// - D-Money - Djibouti
/// - MTC Money - Namibia
/// - GETESA - Equatorial Guinea
class MobileMoneyService {
  static final _log = Logger('MobileMoneyService');

  final MobileMoneyRepository? _repository;

  /// Create service with optional repository for database-backed operations
  MobileMoneyService([this._repository]);

  /// Initialize a payment request with USSD
  ///
  /// [phone] - Customer phone number
  /// [merchantCode] - Merchant code to pay
  /// [amount] - Payment amount
  /// [currency] - Currency code (auto-detected if not provided)
  /// [countryCode] - ISO country code (auto-detected from phone if not provided)
  Future<PaymentResult> initiatePayment({
    required String phone,
    required String merchantCode,
    required double amount,
    String? currency,
    String? countryCode,
    String? reference,
    String? description,
  }) async {
    _log.info('Initiating payment: $amount to merchant $merchantCode');

    // Validate amount
    if (amount <= 0) {
      return PaymentResult.failure(
        code: 'INVALID_AMOUNT',
        message: 'Amount must be greater than zero',
      );
    }

    // Validate merchant code
    if (merchantCode.isEmpty) {
      return PaymentResult.failure(
        code: 'INVALID_MERCHANT',
        message: 'Merchant code is required',
      );
    }

    try {
      // If we have repository, use database-backed flow
      if (_repository != null) {
        return await _initiateWithRepository(
          phone: phone,
          merchantCode: merchantCode,
          amount: amount,
          countryCode: countryCode,
        );
      }

      // Fallback to legacy provider detection
      final provider = detectProvider(phone);
      if (provider == null) {
        return PaymentResult.failure(
          code: 'UNSUPPORTED_PHONE',
          message: 'Phone number not from a supported network',
        );
      }

      return await _processLegacyPayment(
        provider: provider,
        phone: phone,
        merchantCode: merchantCode,
        amount: amount,
        currency: currency ?? 'RWF',
        reference: reference,
        description: description,
      );
    } catch (e) {
      _log.severe('Payment failed: $e');
      return PaymentResult.failure(
        code: 'PAYMENT_ERROR',
        message: 'Payment processing failed. Please try again.',
      );
    }
  }

  /// Repository-backed payment initiation
  Future<PaymentResult> _initiateWithRepository({
    required String phone,
    required String merchantCode,
    required double amount,
    String? countryCode,
  }) async {
    // Detect country
    Country? country;
    if (countryCode != null) {
      final result = await _repository!.getCountryByCode(countryCode);
      country = result.fold((e) => null, (c) => c);
    } else {
      final result = await _repository!.detectCountryFromPhone(phone);
      country = result.fold((e) => null, (c) => c);
    }

    if (country == null) {
      return PaymentResult.failure(
        code: 'UNSUPPORTED_COUNTRY',
        message: 'Phone number not from a supported country',
      );
    }

    // Get primary network
    final networkResult = await _repository.getPrimaryNetwork(
      country.codeAlpha2,
    );
    final network = networkResult.fold((e) => null, (n) => n);

    if (network == null) {
      return PaymentResult.failure(
        code: 'NO_NETWORK',
        message: 'No mobile money network available in ${country.name}',
      );
    }

    // Generate USSD string
    final ussdResult = await _repository.generateUssdString(
      networkId: network.id,
      merchantCode: merchantCode,
      amount: amount,
      phone: phone,
    );

    return ussdResult.fold(
      (error) => PaymentResult.failure(
        code: 'USSD_ERROR',
        message: error.message,
      ),
      (ussdString) {
        final transactionId = 'TX${DateTime.now().millisecondsSinceEpoch}';
        _log.info('Generated USSD: $ussdString for tx: $transactionId');

        return PaymentResult.pending(
          transactionId: transactionId,
          ussdString: ussdString,
          message: 'Dial the USSD code to complete payment',
          country: country,
          network: network,
        );
      },
    );
  }

  /// Legacy payment processing (fallback for Rwanda)
  Future<PaymentResult> _processLegacyPayment({
    required MobileMoneyProvider provider,
    required String phone,
    required String merchantCode,
    required double amount,
    required String currency,
    String? reference,
    String? description,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    final transactionId = '${provider.shortName.toUpperCase()}${DateTime.now().millisecondsSinceEpoch}';
    
    // Generate USSD based on provider
    final ussdString = _generateLegacyUssd(
      provider: provider,
      merchantCode: merchantCode,
      amount: amount,
    );

    _log.info('${provider.displayName} payment initiated: $transactionId');

    return PaymentResult.pending(
      transactionId: transactionId,
      ussdString: ussdString,
      message: 'Dial the USSD code to complete payment',
    );
  }

  /// Generate legacy USSD for Rwanda networks
  String _generateLegacyUssd({
    required MobileMoneyProvider provider,
    required String merchantCode,
    required double amount,
  }) {
    final amountStr = amount.toStringAsFixed(0);
    
    switch (provider) {
      case MobileMoneyProvider.mtnMomo:
        return '*182*8*1*$merchantCode*$amountStr#';
      case MobileMoneyProvider.airtelMoney:
        // Rwanda Airtel Money format
        return '*182*5*$merchantCode*$amountStr#';
      default:
        return '*182*$merchantCode*$amountStr#';
    }
  }

  /// Launch USSD dial intent on device
  ///
  /// Opens the phone dialer with the USSD code
  Future<bool> launchUssdDial(String ussdString) async {
    try {
      // Encode USSD for URI (# becomes %23)
      final encoded = Uri.encodeComponent(ussdString);
      final uri = Uri.parse('tel:$encoded');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _log.info('Launched USSD dial: $ussdString');
        return true;
      } else {
        _log.warning('Cannot launch USSD dial');
        return false;
      }
    } catch (e) {
      _log.severe('Failed to launch USSD: $e');
      return false;
    }
  }

  /// Check payment status
  Future<PaymentStatus> checkStatus(String transactionId) async {
    _log.info('Checking payment status: $transactionId');

    // TODO: Replace with actual status check API call
    await Future.delayed(const Duration(seconds: 1));

    return PaymentStatus.pending;
  }

  /// Validate phone number format for a country
  ///
  /// Returns true if phone matches expected format
  Future<bool> validatePhoneNumber(String phone, {String? countryCode}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    if (cleaned.length < 8) return false;

    if (_repository != null && countryCode != null) {
      final result = await _repository.getCountryByCode(countryCode);
      return result.fold(
        (error) => false,
        (country) => country.matchesPhoneNumber(cleaned),
      );
    }

    // Legacy Rwanda validation
    return _isValidRwandaPhone(cleaned);
  }

  bool _isValidRwandaPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 10 && cleaned.length != 12) return false;

    final normalized = cleaned.length == 12 && cleaned.startsWith('250')
        ? cleaned.substring(3)
        : cleaned;

    // Valid Rwanda prefixes: 072, 073 (Airtel), 078, 079 (MTN)
    return normalized.startsWith('072') ||
        normalized.startsWith('073') ||
        normalized.startsWith('078') ||
        normalized.startsWith('079');
  }

  /// Format phone number for display
  String formatPhoneNumber(String phone, {String? countryCode}) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    
    // Default Rwanda format
    if (cleaned.length == 10) {
      return '+250 ${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    } else if (cleaned.length == 12 && cleaned.startsWith('250')) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
    }
    return phone;
  }

  /// Detect provider from phone number (legacy Rwanda support)
  MobileMoneyProvider? detectProvider(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    final normalized = cleaned.length == 12 && cleaned.startsWith('250')
        ? cleaned.substring(3)
        : cleaned;

    if (normalized.startsWith('078') || normalized.startsWith('079')) {
      return MobileMoneyProvider.mtnMomo;
    } else if (normalized.startsWith('072') || normalized.startsWith('073')) {
      return MobileMoneyProvider.airtelMoney;
    }
    return null;
  }

  /// Get all supported countries
  Future<List<Country>> getSupportedCountries() async {
    if (_repository == null) return [];
    
    final result = await _repository.getCountries();
    return result.fold(
      (error) => [],
      (countries) => countries,
    );
  }

  /// Get networks for a country
  Future<List<MobileMoneyNetwork>> getNetworksForCountry(
    String countryCode,
  ) async {
    if (_repository == null) return [];
    
    final result = await _repository.getNetworksForCountry(countryCode);
    return result.fold(
      (error) => [],
      (networks) => networks,
    );
  }

  /// Detect country from phone number
  Future<Country?> detectCountryFromPhone(String phone) async {
    if (_repository == null) return null;
    
    final result = await _repository.detectCountryFromPhone(phone);
    return result.fold(
      (error) => null,
      (country) => country,
    );
  }
}

/// Supported mobile money providers (legacy enum, kept for backwards compatibility)
enum MobileMoneyProvider {
  mtnMomo('MTN Mobile Money', 'MTN'),
  airtelMoney('Airtel Money', 'Airtel'),
  orangeMoney('Orange Money', 'Orange'),
  ecoCash('EcoCash', 'EcoCash'),
  mPesa('M-Pesa', 'M-Pesa'),
  mvola('MVola', 'MVola'),
  tMoney('T-Money', 'T-Money'),
  moovMoney('Moov Money', 'Moov'),
  dMoney('D-Money', 'D-Money'),
  mtcMoney('MTC Money', 'MTC'),
  getesa('GETESA', 'GETESA');

  final String displayName;
  final String shortName;

  const MobileMoneyProvider(this.displayName, this.shortName);
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  expired,
}

/// Payment result
sealed class PaymentResult {
  const PaymentResult();

  factory PaymentResult.success({
    required String transactionId,
    String? message,
  }) = PaymentSuccess;

  factory PaymentResult.pending({
    required String transactionId,
    String? ussdString,
    String? message,
    Country? country,
    MobileMoneyNetwork? network,
  }) = PaymentPending;

  factory PaymentResult.failure({
    required String code,
    required String message,
  }) = PaymentFailure;
}

class PaymentSuccess extends PaymentResult {
  final String transactionId;
  final String? message;

  const PaymentSuccess({required this.transactionId, this.message});
}

class PaymentPending extends PaymentResult {
  final String transactionId;
  final String? ussdString;
  final String? message;
  final Country? country;
  final MobileMoneyNetwork? network;

  const PaymentPending({
    required this.transactionId,
    this.ussdString,
    this.message,
    this.country,
    this.network,
  });
}

class PaymentFailure extends PaymentResult {
  final String code;
  final String message;

  const PaymentFailure({required this.code, required this.message});
}

/// Payment transaction record
class PaymentTransaction {
  final String id;
  final MobileMoneyProvider provider;
  final String phoneNumber;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? reference;
  final String? errorMessage;
  final String? ussdString;

  const PaymentTransaction({
    required this.id,
    required this.provider,
    required this.phoneNumber,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.reference,
    this.errorMessage,
    this.ussdString,
  });

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending =>
      status == PaymentStatus.pending || status == PaymentStatus.processing;
}
