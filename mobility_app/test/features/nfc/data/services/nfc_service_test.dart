import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/features/nfc/data/services/nfc_service.dart';

void main() {
  group('NFCReadResult', () {
    test('success result has correct properties', () {
      const result = NFCReadResult(
        success: true,
        tagId: 'AA:BB:CC:DD',
        ndefData: {'text': 'Hello'},
        rawRecords: ['Type: T, Payload: Hello'],
      );

      expect(result.success, isTrue);
      expect(result.tagId, equals('AA:BB:CC:DD'));
      expect(result.ndefData, contains('text'));
      expect(result.rawRecords, isNotEmpty);
      expect(result.errorMessage, isNull);
    });

    test('failure result includes error message', () {
      const result = NFCReadResult(
        success: false,
        errorMessage: 'Tag not found',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Tag not found'));
      expect(result.tagId, isNull);
      expect(result.ndefData, isNull);
    });

    test('toString returns human-readable format', () {
      const result = NFCReadResult(
        success: true,
        tagId: 'AA:BB',
        ndefData: {'key': 'value'},
      );

      final str = result.toString();
      expect(str, contains('success: true'));
      expect(str, contains('tagId: AA:BB'));
    });
  });

  group('NFCWriteResult', () {
    test('success write result has null error message', () {
      const result = NFCWriteResult(success: true);

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('failure write result includes error message', () {
      const result = NFCWriteResult(
        success: false,
        errorMessage: 'Tag is read-only',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Tag is read-only'));
    });
  });

  group('PaymentResult', () {
    test('successful payment has all fields populated', () {
      const result = PaymentResult(
        success: true,
        message: 'Payment sent to MTN',
        transactionId: 'TXN-123456',
        amount: 5000,
        currency: 'RWF',
      );

      expect(result.success, isTrue);
      expect(result.message, equals('Payment sent to MTN'));
      expect(result.transactionId, equals('TXN-123456'));
      expect(result.amount, equals(5000));
      expect(result.currency, equals('RWF'));
    });

    test('failed payment has no transaction ID', () {
      const result = PaymentResult(
        success: false,
        message: 'Insufficient balance',
      );

      expect(result.success, isFalse);
      expect(result.transactionId, isNull);
      expect(result.amount, isNull);
    });
  });

  group('NFCService', () {
    test('singleton instance is consistent', () {
      final instance1 = NFCService.instance;
      final instance2 = NFCService.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });
}
