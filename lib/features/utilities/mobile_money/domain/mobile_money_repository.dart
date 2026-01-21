import 'package:dartz/dartz.dart';

import 'country.dart';
import 'mobile_money_network.dart';

/// Repository interface for country and mobile money network data
///
/// Provides methods to fetch countries, networks, and generate USSD strings
abstract class MobileMoneyRepository {
  /// Get all supported countries
  Future<Either<MobileMoneyError, List<Country>>> getCountries();

  /// Get a single country by ISO code (alpha2 or alpha3)
  Future<Either<MobileMoneyError, Country>> getCountryByCode(String code);

  /// Detect country from phone number prefix
  Future<Either<MobileMoneyError, Country>> detectCountryFromPhone(
    String phone,
  );

  /// Get all mobile money networks for a country
  Future<Either<MobileMoneyError, List<MobileMoneyNetwork>>>
      getNetworksForCountry(String countryCode);

  /// Get the primary network for a country
  Future<Either<MobileMoneyError, MobileMoneyNetwork>> getPrimaryNetwork(
    String countryCode,
  );

  /// Get a specific network by ID
  Future<Either<MobileMoneyError, MobileMoneyNetwork>> getNetworkById(
    String networkId,
  );

  /// Generate a USSD dial string
  ///
  /// [networkId] - The network to generate for
  /// [merchantCode] - The merchant code to pay
  /// [amount] - The payment amount
  /// [phone] - Optional phone for P2P transfers
  Future<Either<MobileMoneyError, String>> generateUssdString({
    required String networkId,
    required String merchantCode,
    required double amount,
    String? phone,
  });

  /// Clear cached data
  Future<void> clearCache();
}

/// Error types for mobile money operations
class MobileMoneyError {
  final MobileMoneyErrorType type;
  final String message;
  final dynamic originalError;

  const MobileMoneyError({
    required this.type,
    required this.message,
    this.originalError,
  });

  factory MobileMoneyError.notFound(String message) => MobileMoneyError(
        type: MobileMoneyErrorType.notFound,
        message: message,
      );

  factory MobileMoneyError.network(String message, [dynamic error]) =>
      MobileMoneyError(
        type: MobileMoneyErrorType.network,
        message: message,
        originalError: error,
      );

  factory MobileMoneyError.validation(String message) => MobileMoneyError(
        type: MobileMoneyErrorType.validation,
        message: message,
      );

  factory MobileMoneyError.unknown(String message, [dynamic error]) =>
      MobileMoneyError(
        type: MobileMoneyErrorType.unknown,
        message: message,
        originalError: error,
      );

  @override
  String toString() => 'MobileMoneyError($type): $message';
}

/// Error type enumeration
enum MobileMoneyErrorType {
  notFound,
  network,
  validation,
  unknown,
}
