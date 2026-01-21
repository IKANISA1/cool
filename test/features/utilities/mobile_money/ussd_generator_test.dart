import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/features/utilities/mobile_money/domain/country.dart';
import 'package:ridelink/features/utilities/mobile_money/domain/mobile_money_network.dart';
import 'package:ridelink/features/utilities/mobile_money/domain/ussd_dial_format.dart';

void main() {
  group('Country', () {
    test('fromJson creates country correctly', () {
      final json = {
        'id': 'test-id',
        'code_alpha2': 'RW',
        'code_alpha3': 'RWA',
        'name': 'Rwanda',
        'currency_code': 'RWF',
        'currency_symbol': 'RF',
        'phone_prefix': '+250',
        'is_active': true,
      };

      final country = Country.fromJson(json);

      expect(country.id, 'test-id');
      expect(country.codeAlpha2, 'RW');
      expect(country.codeAlpha3, 'RWA');
      expect(country.name, 'Rwanda');
      expect(country.currencyCode, 'RWF');
      expect(country.currencySymbol, 'RF');
      expect(country.phonePrefix, '+250');
      expect(country.isActive, true);
    });

    test('matchesPhoneNumber validates correctly', () {
      final country = Country(
        id: '1',
        codeAlpha2: 'RW',
        codeAlpha3: 'RWA',
        name: 'Rwanda',
        currencyCode: 'RWF',
        phonePrefix: '+250',
      );

      expect(country.matchesPhoneNumber('+250788123456'), true);
      expect(country.matchesPhoneNumber('250788123456'), true);
      expect(country.matchesPhoneNumber('+255788123456'), false);
    });

    test('toInternationalFormat converts correctly', () {
      final country = Country(
        id: '1',
        codeAlpha2: 'RW',
        codeAlpha3: 'RWA',
        name: 'Rwanda',
        currencyCode: 'RWF',
        phonePrefix: '+250',
      );

      expect(country.toInternationalFormat('0788123456'), '+250788123456');
      expect(country.toInternationalFormat('788123456'), '+250788123456');
    });

    test('flagEmoji returns correct flag', () {
      final rwanda = Country(
        id: '1',
        codeAlpha2: 'RW',
        codeAlpha3: 'RWA',
        name: 'Rwanda',
        currencyCode: 'RWF',
        phonePrefix: '+250',
      );

      expect(rwanda.flagEmoji, '🇷🇼');
    });
  });

  group('MobileMoneyNetwork', () {
    test('fromJson creates network correctly', () {
      final json = {
        'id': 'net-id',
        'country_id': 'country-id',
        'network_name': 'MTN Mobile Money',
        'network_code': 'MTN_MOMO',
        'short_name': 'MTN MoMo',
        'is_primary': true,
        'is_active': true,
      };

      final network = MobileMoneyNetwork.fromJson(json);

      expect(network.id, 'net-id');
      expect(network.countryId, 'country-id');
      expect(network.networkName, 'MTN Mobile Money');
      expect(network.networkCode, 'MTN_MOMO');
      expect(network.shortName, 'MTN MoMo');
      expect(network.isPrimary, true);
    });

    test('generateUssdString replaces placeholders', () {
      final network = MobileMoneyNetwork(
        id: '1',
        countryId: '2',
        networkName: 'MTN MoMo',
        networkCode: 'MTN_MOMO',
        shortName: 'MTN',
        dialTemplate: '*182*8*1*{MERCHANT}*{AMOUNT}#',
      );

      final ussd = network.generateUssdString(
        merchantCode: '12345',
        amount: 5000,
      );

      expect(ussd, '*182*8*1*12345*5000#');
    });

    test('generateUssdString handles phone placeholder', () {
      final network = MobileMoneyNetwork(
        id: '1',
        countryId: '2',
        networkName: 'EcoCash',
        networkCode: 'ECOCASH',
        shortName: 'EcoCash',
        dialTemplate: '*151*1*1*{PHONE}*{AMOUNT}#',
      );

      final ussd = network.generateUssdString(
        merchantCode: '',
        amount: 1000,
        phone: '0788123456',
      );

      expect(ussd, '*151*1*1*0788123456*1000#');
    });

    test('NetworkType.fromCode returns correct type', () {
      expect(NetworkType.fromCode('MTN_MOMO'), NetworkType.mtnMomo);
      expect(NetworkType.fromCode('AIRTEL_MONEY'), NetworkType.airtelMoney);
      expect(NetworkType.fromCode('ORANGE_MONEY'), NetworkType.orangeMoney);
      expect(NetworkType.fromCode('ECOCASH'), NetworkType.ecoCash);
      expect(NetworkType.fromCode('MPESA'), NetworkType.mPesa);
      expect(NetworkType.fromCode('MVOLA'), NetworkType.mvola);
      expect(NetworkType.fromCode('TMONEY'), NetworkType.tMoney);
      expect(NetworkType.fromCode('MOOV_MONEY'), NetworkType.moovMoney);
      expect(NetworkType.fromCode('DMONEY'), NetworkType.dMoney);
      expect(NetworkType.fromCode('MTC_MONEY'), NetworkType.mtcMoney);
      expect(NetworkType.fromCode('GETESA'), NetworkType.getesa);
      expect(NetworkType.fromCode('UNKNOWN'), null);
    });
  });

  group('UssdDialFormat', () {
    test('fromJson creates format correctly', () {
      final json = {
        'id': 'fmt-id',
        'network_id': 'net-id',
        'dial_template': '*182*8*1*{MERCHANT}*{AMOUNT}#',
        'format_type': 'merchant_payment',
        'description': 'Merchant payment',
        'is_active': true,
      };

      final format = UssdDialFormat.fromJson(json);

      expect(format.id, 'fmt-id');
      expect(format.networkId, 'net-id');
      expect(format.dialTemplate, '*182*8*1*{MERCHANT}*{AMOUNT}#');
      expect(format.formatType, UssdFormatType.merchantPayment);
    });

    test('generate replaces all placeholders', () {
      final format = UssdDialFormat(
        id: '1',
        networkId: '2',
        dialTemplate: '*182*8*1*{MERCHANT}*{AMOUNT}#',
      );

      final result = format.generate(merchantCode: '99999', amount: 10000);
      expect(result, '*182*8*1*99999*10000#');
    });

    test('generate with phone placeholder', () {
      final format = UssdDialFormat(
        id: '1',
        networkId: '2',
        dialTemplate: '*151*1*1*{PHONE}*{AMOUNT}#',
      );

      final result = format.generate(
        phone: '+250788123456',
        amount: 5000,
      );
      expect(result, '*151*1*1*250788123456*5000#');
    });

    test('requiredPlaceholders identifies correctly', () {
      final format = UssdDialFormat(
        id: '1',
        networkId: '2',
        dialTemplate: '*182*{MERCHANT}*{AMOUNT}#',
      );

      expect(format.requiresMerchant, true);
      expect(format.requiresAmount, true);
      expect(format.requiresPhone, false);
      expect(format.requiredPlaceholders, [
        UssdPlaceholder.merchant,
        UssdPlaceholder.amount,
      ]);
    });

    test('UssdFormatType.fromString parses correctly', () {
      expect(
        UssdFormatType.fromString('merchant_payment'),
        UssdFormatType.merchantPayment,
      );
      expect(
        UssdFormatType.fromString('p2p_transfer'),
        UssdFormatType.p2pTransfer,
      );
      expect(
        UssdFormatType.fromString('balance_check'),
        UssdFormatType.balanceCheck,
      );
      expect(
        UssdFormatType.fromString('withdrawal'),
        UssdFormatType.withdrawal,
      );
      expect(
        UssdFormatType.fromString('unknown'),
        UssdFormatType.merchantPayment,
      );
    });
  });

  group('USSD Generation for All 28 Countries', () {
    // Test cases based on user-provided data
    final testCases = <String, Map<String, dynamic>>{
      'Burundi': {
        'template': '*151*1*1*{PHONE}*{AMOUNT}#',
        'merchant': '0799999',
        'amount': 5000.0,
        'expected': '*151*1*1*0799999*5000#',
      },
      'Cameroon': {
        'template': '*126*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '12345',
        'amount': 10000.0,
        'expected': '*126*4*12345*10000#',
      },
      'Madagascar': {
        'template': '#111*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '54321',
        'amount': 50000.0,
        'expected': '#111*4*54321*50000#',
      },
      'Rwanda': {
        'template': '*182*8*1*{MERCHANT}*{AMOUNT}#',
        'merchant': '25678',
        'amount': 15000.0,
        'expected': '*182*8*1*25678*15000#',
      },
      'Seychelles': {
        'template': '*202*{MERCHANT}*{AMOUNT}#',
        'merchant': '99999',
        'amount': 500.0,
        'expected': '*202*99999*500#',
      },
      'Tanzania': {
        'template': '*150*00*{MERCHANT}*{AMOUNT}#',
        'merchant': '888888',
        'amount': 25000.0,
        'expected': '*150*00*888888*25000#',
      },
      'Zambia': {
        'template': '*115*5*{MERCHANT}*{AMOUNT}#',
        'merchant': '77777',
        'amount': 100.0,
        'expected': '*115*5*77777*100#',
      },
      'Zimbabwe': {
        'template': '*151*2*{MERCHANT}*{AMOUNT}#',
        'merchant': '66666',
        'amount': 200.0,
        'expected': '*151*2*66666*200#',
      },
      'Malawi': {
        'template': '*211*{MERCHANT}*{AMOUNT}#',
        'merchant': '55555',
        'amount': 5000.0,
        'expected': '*211*55555*5000#',
      },
      'Namibia': {
        'template': '*140*682*{MERCHANT}*{AMOUNT}#',
        'merchant': '44444',
        'amount': 350.0,
        'expected': '*140*682*44444*350#',
      },
      'Ghana': {
        'template': '*170*2*1*{MERCHANT}*{AMOUNT}#',
        'merchant': '33333',
        'amount': 100.0,
        'expected': '*170*2*1*33333*100#',
      },
      'Benin': {
        'template': '*880*3*{MERCHANT}*{AMOUNT}#',
        'merchant': '22222',
        'amount': 2500.0,
        'expected': '*880*3*22222*2500#',
      },
      'Burkina Faso': {
        'template': '*144*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '11111',
        'amount': 5000.0,
        'expected': '*144*4*11111*5000#',
      },
      'CAR': {
        'template': '#150*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '12121',
        'amount': 10000.0,
        'expected': '#150*4*12121*10000#',
      },
      'Chad': {
        'template': '*211*{MERCHANT}*{AMOUNT}#',
        'merchant': '21212',
        'amount': 7500.0,
        'expected': '*211*21212*7500#',
      },
      'Comoros': {
        'template': '*150*01*1*2*{MERCHANT}*{AMOUNT}#',
        'merchant': '31313',
        'amount': 15000.0,
        'expected': '*150*01*1*2*31313*15000#',
      },
      'Congo': {
        'template': '*133*5*{MERCHANT}*{AMOUNT}#',
        'merchant': '41414',
        'amount': 20000.0,
        'expected': '*133*5*41414*20000#',
      },
      'Cote d\'Ivoire': {
        'template': '*144*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '51515',
        'amount': 25000.0,
        'expected': '*144*4*51515*25000#',
      },
      'DR Congo': {
        'template': '*144*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '61616',
        'amount': 50000.0,
        'expected': '*144*4*61616*50000#',
      },
      'Djibouti': {
        'template': '*133*{MERCHANT}*{AMOUNT}#',
        'merchant': '71717',
        'amount': 1000.0,
        'expected': '*133*71717*1000#',
      },
      'Equatorial Guinea': {
        'template': '*222*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '81818',
        'amount': 75000.0,
        'expected': '*222*4*81818*75000#',
      },
      'Gabon': {
        'template': '*150*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '91919',
        'amount': 30000.0,
        'expected': '*150*4*91919*30000#',
      },
      'Guinea': {
        'template': '*144*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '10101',
        'amount': 100000.0,
        'expected': '*144*4*10101*100000#',
      },
      'Mali': {
        'template': '#144#*2*{MERCHANT}*{AMOUNT}#',
        'merchant': '20202',
        'amount': 15000.0,
        'expected': '#144#*2*20202*15000#',
      },
      'Mauritania': {
        'template': '*900*4*{MERCHANT}*{AMOUNT}#',
        'merchant': '30303',
        'amount': 5000.0,
        'expected': '*900*4*30303*5000#',
      },
      'Niger': {
        'template': '*400*{MERCHANT}*{AMOUNT}#',
        'merchant': '40404',
        'amount': 7500.0,
        'expected': '*400*40404*7500#',
      },
      'Senegal': {
        'template': '#144*2*{MERCHANT}*{AMOUNT}#',
        'merchant': '50505',
        'amount': 10000.0,
        'expected': '#144*2*50505*10000#',
      },
      'Togo': {
        'template': '*145*3*{MERCHANT}*{AMOUNT}#',
        'merchant': '60606',
        'amount': 2500.0,
        'expected': '*145*3*60606*2500#',
      },
    };

    for (final entry in testCases.entries) {
      test('generates correct USSD for ${entry.key}', () {
        final format = UssdDialFormat(
          id: '1',
          networkId: '2',
          dialTemplate: entry.value['template'] as String,
        );

        String result;
        if (entry.value['template'].toString().contains('{PHONE}')) {
          result = format.generate(
            phone: entry.value['merchant'] as String,
            amount: entry.value['amount'] as double,
          );
        } else {
          result = format.generate(
            merchantCode: entry.value['merchant'] as String,
            amount: entry.value['amount'] as double,
          );
        }

        expect(result, entry.value['expected']);
      });
    }
  });
}
