// ============================================================================
// NFC SERVICE - shared/services/nfc_service.dart (nfc_manager v4 compatible)
// ============================================================================

import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'dart:io';

class NFCService {
  /// Check if NFC is available
  Future<bool> isAvailable() async {
    // ignore: deprecated_member_use
    return await NfcManager.instance.isAvailable();
  }

  /// Start NFC session (read)
  Future<String?> startNFCRead() async {
    String? result;
    
    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        // Use the NdefAndroid class from nfc_manager v4
        final ndef = NdefAndroid.from(tag);
        if (ndef != null) {
          final cachedMessage = ndef.cachedNdefMessage;
          if (cachedMessage != null) {
            for (var record in cachedMessage.records) {
              // Skip the language code byte for text records
              if (record.payload.isNotEmpty) {
                result = String.fromCharCodes(record.payload.skip(1));
              }
            }
          }
        }
        await NfcManager.instance.stopSession();
      },
    );
    
    return result; 
  }

  /// Write NFC tag (Android only)
  Future<bool> writeNFCTag(String data) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('NFC write is only supported on Android');
    }

    bool success = false;

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        final ndef = NdefAndroid.from(tag);
        if (ndef != null && ndef.isWritable) {
          // Create a text record using ndef_record package
          final languageCode = 'en';
          final languageCodeBytes = languageCode.codeUnits;
          final textBytes = data.codeUnits;
          final payload = Uint8List.fromList([
            languageCodeBytes.length,
            ...languageCodeBytes,
            ...textBytes,
          ]);
          
          final record = NdefRecord(
            typeNameFormat: TypeNameFormat.wellKnown,
            type: Uint8List.fromList([0x54]), // 'T' for text
            identifier: Uint8List(0),
            payload: payload,
          );
          
          final message = NdefMessage(records: [record]);
          
          try {
            await ndef.writeNdefMessage(message);
            success = true;
          } catch (e) {
            success = false;
          }
        }
        await NfcManager.instance.stopSession();
      },
    );

    return success;
  }

  /// Stop NFC session
  Future<void> stopSession() async {
    await NfcManager.instance.stopSession();
  }
}
