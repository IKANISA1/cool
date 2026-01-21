import 'package:dartz/dartz.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/country.dart';
import '../domain/mobile_money_network.dart';
import '../domain/mobile_money_repository.dart';

/// Supabase-backed implementation of MobileMoneyRepository
///
/// Provides caching and efficient data access for countries and networks
class MobileMoneyRepositoryImpl implements MobileMoneyRepository {
  final SupabaseClient _supabase;
  static final _log = Logger('MobileMoneyRepository');

  // In-memory cache
  List<Country>? _countriesCache;
  final Map<String, List<MobileMoneyNetwork>> _networksCache = {};
  DateTime? _cacheExpiry;

  static const _cacheDuration = Duration(hours: 24);

  MobileMoneyRepositoryImpl(this._supabase);

  /// Check if cache is valid
  bool get _isCacheValid =>
      _cacheExpiry != null && DateTime.now().isBefore(_cacheExpiry!);

  @override
  Future<Either<MobileMoneyError, List<Country>>> getCountries() async {
    try {
      // Return cached data if valid
      if (_isCacheValid && _countriesCache != null) {
        return Right(_countriesCache!);
      }

      final response = await _supabase
          .from('countries')
          .select()
          .eq('is_active', true)
          .order('name');

      final countries = (response as List)
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _countriesCache = countries;
      _cacheExpiry = DateTime.now().add(_cacheDuration);

      _log.info('Loaded ${countries.length} countries');
      return Right(countries);
    } catch (e) {
      _log.severe('Failed to load countries: $e');
      return Left(MobileMoneyError.network('Failed to load countries', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, Country>> getCountryByCode(
    String code,
  ) async {
    try {
      // Try cache first
      final countriesResult = await getCountries();
      return countriesResult.fold(
        (error) => Left(error),
        (countries) {
          final upperCode = code.toUpperCase();
          final country = countries.where((c) =>
              c.codeAlpha2 == upperCode || c.codeAlpha3 == upperCode);

          if (country.isEmpty) {
            return Left(
              MobileMoneyError.notFound('Country not found: $code'),
            );
          }
          return Right(country.first);
        },
      );
    } catch (e) {
      _log.severe('Failed to get country: $e');
      return Left(MobileMoneyError.network('Failed to get country', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, Country>> detectCountryFromPhone(
    String phone,
  ) async {
    try {
      final response = await _supabase
          .rpc('detect_country_from_phone', params: {'p_phone': phone});

      if (response == null || (response as List).isEmpty) {
        return Left(
          MobileMoneyError.notFound('No country found for phone: $phone'),
        );
      }

      final countryData = response[0] as Map<String, dynamic>;
      
      // Fetch full country data
      return getCountryByCode(countryData['code_alpha2'] as String);
    } catch (e) {
      _log.severe('Failed to detect country: $e');
      return Left(MobileMoneyError.network('Failed to detect country', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, List<MobileMoneyNetwork>>>
      getNetworksForCountry(String countryCode) async {
    try {
      // Check cache
      final cacheKey = countryCode.toUpperCase();
      if (_isCacheValid && _networksCache.containsKey(cacheKey)) {
        return Right(_networksCache[cacheKey]!);
      }

      final response = await _supabase.rpc(
        'get_networks_for_country',
        params: {'p_country_code': countryCode},
      );

      if (response == null) {
        return Right([]);
      }

      final networks = (response as List)
          .map((json) =>
              MobileMoneyNetwork.fromRpcResult(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _networksCache[cacheKey] = networks;

      _log.info('Loaded ${networks.length} networks for $countryCode');
      return Right(networks);
    } catch (e) {
      _log.severe('Failed to load networks: $e');
      return Left(MobileMoneyError.network('Failed to load networks', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, MobileMoneyNetwork>> getPrimaryNetwork(
    String countryCode,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_primary_network',
        params: {'p_country_code': countryCode},
      );

      if (response == null || (response as List).isEmpty) {
        return Left(
          MobileMoneyError.notFound(
            'No primary network for country: $countryCode',
          ),
        );
      }

      final network = MobileMoneyNetwork.fromRpcResult(
        response[0] as Map<String, dynamic>,
      );

      return Right(network);
    } catch (e) {
      _log.severe('Failed to get primary network: $e');
      return Left(MobileMoneyError.network('Failed to get primary network', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, MobileMoneyNetwork>> getNetworkById(
    String networkId,
  ) async {
    try {
      final response = await _supabase
          .from('mobile_money_networks')
          .select('''
            *,
            ussd_dial_formats!inner(dial_template)
          ''')
          .eq('id', networkId)
          .single();

      final dialTemplateList = response['ussd_dial_formats'] as List?;
      final dialTemplate = dialTemplateList?.isNotEmpty == true
          ? dialTemplateList![0]['dial_template'] as String?
          : null;

      final network = MobileMoneyNetwork.fromJson(response);
      return Right(network.copyWith(dialTemplate: dialTemplate));
    } catch (e) {
      _log.severe('Failed to get network: $e');
      return Left(MobileMoneyError.network('Failed to get network', e));
    }
  }

  @override
  Future<Either<MobileMoneyError, String>> generateUssdString({
    required String networkId,
    required String merchantCode,
    required double amount,
    String? phone,
  }) async {
    try {
      // Validate inputs
      if (merchantCode.isEmpty) {
        return Left(
          MobileMoneyError.validation('Merchant code is required'),
        );
      }
      if (amount <= 0) {
        return Left(
          MobileMoneyError.validation('Amount must be greater than zero'),
        );
      }

      final response = await _supabase.rpc(
        'generate_ussd_dial_string',
        params: {
          'p_network_id': networkId,
          'p_merchant_code': merchantCode,
          'p_amount': amount,
          'p_phone': phone,
          'p_format_type': 'merchant_payment',
        },
      );

      if (response == null) {
        return Left(
          MobileMoneyError.notFound('No USSD format found for network'),
        );
      }

      return Right(response as String);
    } catch (e) {
      _log.severe('Failed to generate USSD: $e');
      return Left(MobileMoneyError.network('Failed to generate USSD', e));
    }
  }

  @override
  Future<void> clearCache() async {
    _countriesCache = null;
    _networksCache.clear();
    _cacheExpiry = null;
    _log.info('Cache cleared');
  }
}
