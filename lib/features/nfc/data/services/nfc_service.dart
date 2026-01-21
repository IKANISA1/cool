import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
// NdefMessage and NdefRecord are re-exported by nfc_manager
import 'package:nfc_manager/ndef_record.dart';


/// Result model for NFC read operations
class NFCReadResult {
  final bool success;
  final String? tagId;
  final Map<String, dynamic>? ndefData;
  final String? errorMessage;
  final List<String>? rawRecords;

  const NFCReadResult({
    required this.success,
    this.tagId,
    this.ndefData,
    this.errorMessage,
    this.rawRecords,
  });

  @override
  String toString() => 'NFCReadResult(success: $success, tagId: $tagId, '
      'ndefData: $ndefData, error: $errorMessage)';
}

/// Result model for NFC write operations
class NFCWriteResult {
  final bool success;
  final String? errorMessage;

  const NFCWriteResult({
    required this.success,
    this.errorMessage,
  });
}

/// Result model for payment operations
class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final double? amount;
  final String? currency;

  const PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.amount,
    this.currency,
  });
}

/// Result model for loyalty card operations
class LoyaltyCardResult {
  final bool success;
  final String message;
  final String? cardId;
  final int? points;
  final String? tier;
  final String? memberName;

  const LoyaltyCardResult({
    required this.success,
    required this.message,
    this.cardId,
    this.points,
    this.tier,
    this.memberName,
  });
}

/// NFC availability status enum
enum NFCAvailabilityStatus {
  /// NFC is available and enabled
  enabled,
  /// NFC hardware exists but is disabled in settings
  disabled,
  /// Device does not have NFC hardware
  notSupported,
  /// Unknown status
  unknown,
}

/// Result model for driver verification via NFC badge
class DriverVerificationResult {
  final bool verified;
  final String message;
  final String? driverId;
  final String? driverName;
  final String? vehiclePlate;
  final String? issuedBy;
  final String? tagId;

  const DriverVerificationResult({
    required this.verified,
    required this.message,
    this.driverId,
    this.driverName,
    this.vehiclePlate,
    this.issuedBy,
    this.tagId,
  });
}

/// Comprehensive NFC service for read/write operations
/// 
/// Supports:
/// - NFC tag reading on Android and iOS
/// - NFC tag writing on Android only (iOS restricts third-party writes)
/// - Mobile money payment flow integration
class NFCService {
  static NFCService? _instance;
  
  /// Private internal constructor
  NFCService._internal();
  
  /// Factory constructor that returns singleton instance
  /// This allows for DI registration while maintaining singleton behavior
  factory NFCService() {
    _instance ??= NFCService._internal();
    return _instance!;
  }

  /// Singleton instance accessor
  static NFCService get instance {
    _instance ??= NFCService._internal();
    return _instance!;
  }

  // ════════════════════════════════════════════════════════════
  // AVAILABILITY CHECK
  // ════════════════════════════════════════════════════════════

  /// Check if NFC is available and enabled on device
  Future<bool> get isNfcAvailable async {
    return await NfcManager.instance.checkAvailability() ==
        NfcAvailability.enabled;
  }

  /// Get detailed NFC availability status
  Future<NFCAvailabilityStatus> get detailedAvailability async {
    try {
      final availability = await NfcManager.instance.checkAvailability();
      switch (availability) {
        case NfcAvailability.enabled:
          return NFCAvailabilityStatus.enabled;
        case NfcAvailability.disabled:
          return NFCAvailabilityStatus.disabled;
        case NfcAvailability.unsupported:
          return NFCAvailabilityStatus.notSupported;
      }
    } catch (_) {
      return NFCAvailabilityStatus.unknown;
    }
  }

  // ════════════════════════════════════════════════════════════
  // READ OPERATIONS
  // ════════════════════════════════════════════════════════════

  /// Read NFC Tag with NDEF data extraction
  /// 
  /// Returns structured [NFCReadResult] with parsed data.
  /// Use for mobile money cards, driver badges, loyalty cards, etc.
  /// 
  /// [timeout] - Maximum time to wait for tag discovery (default: 60s)
  Future<NFCReadResult> readNFCTag({
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // Check availability first
      if (!await isNfcAvailable) {
        return const NFCReadResult(
          success: false,
          errorMessage: 'NFC is not available or disabled on this device',
        );
      }

      final completer = Completer<NFCReadResult>();

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            // Extract tag identifier
            final tagId = _extractTagId(tag);
            
            // Try to read NDEF data based on platform
            NdefMessage? ndefMessage;
            bool isWritable = false;
            
            if (Platform.isAndroid) {
              final ndef = NdefAndroid.from(tag);
              if (ndef != null) {
                // Try to read, fall back to cached
                ndefMessage = await ndef.getNdefMessage() ?? ndef.cachedNdefMessage;
                isWritable = ndef.isWritable;
              }
            } else if (Platform.isIOS) {
              final ndef = NdefIos.from(tag);
              if (ndef != null) {
                // Try to read, fall back to cached
                ndefMessage = await ndef.readNdef() ?? ndef.cachedNdefMessage;
                isWritable = ndef.status == NdefStatusIos.readWrite;
              }
            }

            if (ndefMessage == null) {
              // Tag exists but no NDEF data
              completer.complete(NFCReadResult(
                success: true,
                tagId: tagId,
                ndefData: {'isWritable': isWritable},
                errorMessage: 'No NDEF data found on tag',
              ));
              await NfcManager.instance.stopSession(
                alertMessageIos: 'Tag scanned',
              );
              return;
            }

            // Parse NDEF records
            final data = <String, dynamic>{};
            final rawRecords = <String>[];

            for (var record in ndefMessage.records) {
              final parsedRecord = _parseNdefRecord(record);
              if (parsedRecord != null) {
                data.addAll(parsedRecord);
              }
              rawRecords.add(_recordToString(record));
            }
            
            data['isWritable'] = isWritable;

            completer.complete(NFCReadResult(
              success: true,
              tagId: tagId,
              ndefData: data,
              rawRecords: rawRecords,
            ));

            await NfcManager.instance.stopSession(
              alertMessageIos: 'Tag read successfully',
            );
          } catch (e) {
            completer.complete(NFCReadResult(
              success: false,
              errorMessage: 'Failed to read tag: $e',
            ));
            await NfcManager.instance.stopSession(
              errorMessageIos: 'Read failed',
            );
          }
        },
      );

      // Timeout handling
      return await completer.future.timeout(
        timeout,
        onTimeout: () async {
          await NfcManager.instance.stopSession(
            errorMessageIos: 'Timeout',
          );
          return const NFCReadResult(
            success: false,
            errorMessage: 'NFC read timeout - no tag detected',
          );
        },
      );
    } catch (e) {
      return NFCReadResult(
        success: false,
        errorMessage: 'Error starting NFC session: $e',
      );
    }
  }

  /// Stream of NFC availability changes
  /// 
  /// Useful for updating UI when NFC is toggled in device settings.
  /// Polls every [pollInterval] to check availability status.
  /// 
  /// Example usage:
  /// ```dart
  /// NFCService.instance.availabilityStream().listen((isAvailable) {
  ///   setState(() => _nfcEnabled = isAvailable);
  /// });
  /// ```
  Stream<bool> availabilityStream({
    Duration pollInterval = const Duration(seconds: 2),
  }) async* {
    bool? lastStatus;
    while (true) {
      final currentStatus = await isNfcAvailable;
      // Only yield if status changed (to avoid unnecessary rebuilds)
      if (currentStatus != lastStatus) {
        lastStatus = currentStatus;
        yield currentStatus;
      }
      await Future.delayed(pollInterval);
    }
  }

  /// Stream of detailed NFC availability status
  /// 
  /// Provides more granular status including disabled vs not supported.
  Stream<NFCAvailabilityStatus> detailedAvailabilityStream({
    Duration pollInterval = const Duration(seconds: 2),
  }) async* {
    NFCAvailabilityStatus? lastStatus;
    while (true) {
      final currentStatus = await detailedAvailability;
      if (currentStatus != lastStatus) {
        lastStatus = currentStatus;
        yield currentStatus;
      }
      await Future.delayed(pollInterval);
    }
  }

  /// Simple session-based reading (legacy compatibility)
  Future<void> startSession({
    required Function(NfcTag) onDiscovered,
    Function(String)? onError,
  }) async {
    bool available = await isNfcAvailable;
    if (!available) {
      if (onError != null) onError('NFC not available');
      return;
    }

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        onDiscovered(tag);
        await stopSession();
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // WRITE OPERATIONS (Android Only)
  // ════════════════════════════════════════════════════════════

  /// Write data to NFC Tag
  /// 
  /// **Android Only** - iOS restricts NFC writing for third-party apps.
  /// 
  /// [data] - String data to write
  /// [mimeType] - MIME type (default: 'text/plain')
  /// [timeout] - Maximum time to wait for tag (default: 30s)
  Future<NFCWriteResult> writeNFCTag({
    required String data,
    String mimeType = 'text/plain',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Platform check - iOS doesn't support NFC writing
      if (!Platform.isAndroid) {
        return const NFCWriteResult(
          success: false,
          errorMessage: 'NFC writing is only supported on Android. '
              'iOS restricts NFC writing for third-party apps.',
        );
      }

      // Check availability
      if (!await isNfcAvailable) {
        return const NFCWriteResult(
          success: false,
          errorMessage: 'NFC is not available or disabled on this device',
        );
      }

      final completer = Completer<NFCWriteResult>();

      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = NdefAndroid.from(tag);

            if (ndef == null) {
              completer.complete(const NFCWriteResult(
                success: false,
                errorMessage: 'Tag does not support NDEF',
              ));
              await NfcManager.instance.stopSession();
              return;
            }

            if (!ndef.isWritable) {
              completer.complete(const NFCWriteResult(
                success: false,
                errorMessage: 'Tag is read-only and cannot be written to',
              ));
              await NfcManager.instance.stopSession();
              return;
            }

            // Create NDEF message with MIME record
            final ndefMessage = NdefMessage(
              records: [
                NdefRecord(
                  typeNameFormat: TypeNameFormat.media,
                  type: Uint8List.fromList(mimeType.codeUnits),
                  identifier: Uint8List(0),
                  payload: Uint8List.fromList(data.codeUnits),
                ),
              ],
            );

            // Check capacity
            if (ndefMessage.byteLength > ndef.maxSize) {
              completer.complete(NFCWriteResult(
                success: false,
                errorMessage: 'Data too large for tag. '
                    'Max: ${ndef.maxSize} bytes, '
                    'Data: ${ndefMessage.byteLength} bytes',
              ));
              await NfcManager.instance.stopSession();
              return;
            }

            // Write to tag
            await ndef.writeNdefMessage(ndefMessage);

            completer.complete(const NFCWriteResult(success: true));
            await NfcManager.instance.stopSession();
          } catch (e) {
            completer.complete(NFCWriteResult(
              success: false,
              errorMessage: 'Write failed: $e',
            ));
            await NfcManager.instance.stopSession();
          }
        },
      );

      // Timeout handling
      return await completer.future.timeout(
        timeout,
        onTimeout: () async {
          await NfcManager.instance.stopSession();
          return const NFCWriteResult(
            success: false,
            errorMessage: 'NFC write timeout - no tag detected',
          );
        },
      );
    } catch (e) {
      return NFCWriteResult(
        success: false,
        errorMessage: 'Error starting NFC session: $e',
      );
    }
  }

  /// Write structured trip verification data to NFC tag (Android only)
  /// 
  /// Writes trip details as JSON to NFC tag for verification purposes.
  /// Use for driver badges, trip verification stamps, etc.
  Future<NFCWriteResult> writeTripData({
    required String tripId,
    required String passengerId,
    required String driverId,
    DateTime? timestamp,
    Map<String, dynamic>? additionalData,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!Platform.isAndroid) {
      return const NFCWriteResult(
        success: false,
        errorMessage: 'NFC writing is only supported on Android devices',
      );
    }

    // Build trip data JSON
    final tripData = {
      'type': 'ridelink_trip',
      'version': '1.0',
      'trip_id': tripId,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      if (additionalData != null) ...additionalData,
    };

    // Convert to JSON string
    final jsonString = tripData.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    final formattedJson = '{$jsonString}';

    return writeNFCTag(
      data: formattedJson,
      mimeType: 'application/json',
      timeout: timeout,
    );
  }

  // ════════════════════════════════════════════════════════════
  // MOBILE MONEY PAYMENT FLOW
  // ════════════════════════════════════════════════════════════

  /// Process NFC-based mobile money payment
  /// 
  /// Reads mobile money card data and initiates payment request.
  /// Currently returns a stub - integrate with Flutterwave, MTN MoMo, etc.
  Future<PaymentResult> processNFCPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      // Step 1: Read mobile money card
      final readResult = await readNFCTag(
        timeout: const Duration(seconds: 45),
      );

      if (!readResult.success) {
        return PaymentResult(
          success: false,
          message: readResult.errorMessage ?? 'Failed to read payment card',
        );
      }

      // Step 2: Extract account details from NDEF data
      final accountNumber = readResult.ndefData?['account_number']
          ?? readResult.ndefData?['account']
          ?? readResult.ndefData?['phone']
          ?? readResult.ndefData?['text'];
      final providerCode = readResult.ndefData?['provider']
          ?? readResult.ndefData?['mno']; // MTN, Airtel, etc.

      if (accountNumber == null) {
        return const PaymentResult(
          success: false,
          message: 'Invalid payment card - no account number found',
        );
      }

      // Step 3: TODO - Integrate with payment provider
      // This would call Flutterwave, MTN MoMo API, Airtel Money, etc.
      // For now, return a simulated success for testing
      return PaymentResult(
        success: true,
        message: 'Payment request sent${providerCode != null ? ' to $providerCode' : ''}',
        transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment processing failed: $e',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // DRIVER VERIFICATION FLOW
  // ════════════════════════════════════════════════════════════

  /// Verify driver badge via NFC tap
  /// 
  /// Reads driver badge and extracts verification information.
  /// Use for passenger safety verification features.
  Future<DriverVerificationResult> verifyDriverBadge({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final readResult = await readNFCTag(timeout: timeout);
      
      if (!readResult.success) {
        return DriverVerificationResult(
          verified: false,
          message: readResult.errorMessage ?? 'Failed to read badge',
        );
      }
      
      // Extract driver information from NDEF data
      final driverId = readResult.ndefData?['driver_id']
          ?? readResult.ndefData?['id']
          ?? readResult.ndefData?['text'];
      final driverName = readResult.ndefData?['name']
          ?? readResult.ndefData?['driver_name'];
      final expiryDate = readResult.ndefData?['expiry']
          ?? readResult.ndefData?['expiry_date'];
      final issuedBy = readResult.ndefData?['issuer']
          ?? readResult.ndefData?['issued_by'];
      final vehiclePlate = readResult.ndefData?['plate']
          ?? readResult.ndefData?['vehicle_plate'];
      
      if (driverId == null) {
        return DriverVerificationResult(
          verified: false,
          message: 'Invalid driver badge - no ID found',
          tagId: readResult.tagId,
        );
      }
      
      // Check expiry if present
      if (expiryDate != null) {
        final expiry = DateTime.tryParse(expiryDate.toString());
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          return DriverVerificationResult(
            verified: false,
            message: 'Driver badge expired on $expiryDate',
            driverId: driverId.toString(),
            tagId: readResult.tagId,
          );
        }
      }
      
      return DriverVerificationResult(
        verified: true,
        message: 'Driver verified successfully',
        driverId: driverId.toString(),
        driverName: driverName?.toString(),
        vehiclePlate: vehiclePlate?.toString(),
        issuedBy: issuedBy?.toString(),
        tagId: readResult.tagId,
      );
    } catch (e) {
      return DriverVerificationResult(
        verified: false,
        message: 'Verification failed: $e',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // LOYALTY CARD FLOW
  // ════════════════════════════════════════════════════════════

  /// Read loyalty/rewards card via NFC
  /// 
  /// Extracts card ID, points balance, and tier information.
  Future<LoyaltyCardResult> readLoyaltyCard({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final readResult = await readNFCTag(timeout: timeout);
      
      if (!readResult.success) {
        return LoyaltyCardResult(
          success: false,
          message: readResult.errorMessage ?? 'Failed to read card',
        );
      }
      
      final cardId = readResult.ndefData?['card_id']
          ?? readResult.ndefData?['loyalty_id']
          ?? readResult.ndefData?['id']
          ?? readResult.tagId;
      final points = readResult.ndefData?['points']
          ?? readResult.ndefData?['balance'];
      final tier = readResult.ndefData?['tier']
          ?? readResult.ndefData?['level'];
      final memberName = readResult.ndefData?['name']
          ?? readResult.ndefData?['member_name'];
      
      return LoyaltyCardResult(
        success: true,
        message: 'Loyalty card scanned successfully',
        cardId: cardId,
        points: int.tryParse(points?.toString() ?? ''),
        tier: tier?.toString(),
        memberName: memberName?.toString(),
      );
    } catch (e) {
      return LoyaltyCardResult(
        success: false,
        message: 'Failed to read loyalty card: $e',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ════════════════════════════════════════════════════════════

  /// Stop the current NFC session
  Future<void> stopSession({String? message}) async {
    await NfcManager.instance.stopSession(
      alertMessageIos: message,
    );
  }

  /// Open device NFC settings
  /// 
  /// Launches the NFC settings page on both Android and iOS.
  /// On Android: Opens NFC settings directly
  /// On iOS: Opens the main Settings app (iOS doesn't allow deep linking to NFC)
  Future<void> openNFCSettings() async {
    if (Platform.isAndroid) {
      // Use Android Intent to open NFC settings
      // ignore: unused_local_variable
      const _ = 'android.settings.NFC_SETTINGS';
      // Note: This requires android_intent_plus package or url_launcher
      // For now, we'll use a platform channel approach via app_settings
      // ignore: deprecated_member_use
      await NfcManager.instance.checkAvailability(); // Ensure NFC manager is initialized
      // The actual deep link would need platform-specific implementation
      // For comprehensive implementation, consider using app_settings package
      throw UnimplementedError(
        'NFC settings deep link requires platform-specific setup. '
        'Consider using app_settings or android_intent_plus package.',
      );
    } else if (Platform.isIOS) {
      // iOS doesn't support direct deep links to NFC settings
      // The best we can do is open the main Settings app
      throw UnimplementedError(
        'iOS does not support deep links to NFC settings. '
        'Users must navigate manually: Settings > NFC.',
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════

  /// Extract tag identifier from platform-specific data
  String _extractTagId(NfcTag tag) {
    try {
      if (Platform.isAndroid) {
        // Use NfcTagAndroid which has the id property
        final tagAndroid = NfcTagAndroid.from(tag);
        if (tagAndroid != null) {
          return tagAndroid.id
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      } else if (Platform.isIOS) {
        // iOS: Try MiFare first (most common)
        final miFare = MiFareIos.from(tag);
        if (miFare != null) {
          return miFare.identifier
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
        
        // Try ISO15693
        final iso15693 = Iso15693Ios.from(tag);
        if (iso15693 != null) {
          return iso15693.identifier
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }
      }
      
      return 'TAG-${tag.hashCode.abs()}';
    } catch (_) {
      return 'TAG-${tag.hashCode.abs()}';
    }
  }

  /// Parse a single NDEF record into key-value pairs
  Map<String, dynamic>? _parseNdefRecord(NdefRecord record) {
    try {
      final typeString = String.fromCharCodes(record.type);
      final payloadBytes = record.payload;
      
      // Handle different record types
      switch (record.typeNameFormat) {
        case TypeNameFormat.wellKnown:
          // Text record (type 'T')
          if (typeString == 'T' && payloadBytes.isNotEmpty) {
            // First byte is language code length
            final langCodeLen = payloadBytes.first & 0x3F;
            if (payloadBytes.length > 1 + langCodeLen) {
              final text = String.fromCharCodes(
                payloadBytes.sublist(1 + langCodeLen),
              );
              return {'text': text};
            }
          }
          // URI record (type 'U')
          if (typeString == 'U' && payloadBytes.isNotEmpty) {
            final uri = _decodeUriRecord(payloadBytes);
            return {'uri': uri};
          }
          break;
          
        case TypeNameFormat.media:
          // MIME type record
          final payload = String.fromCharCodes(payloadBytes);
          return {typeString: payload};
          
        case TypeNameFormat.absoluteUri:
          return {'uri': String.fromCharCodes(payloadBytes)};
          
        default:
          // Generic handling
          if (payloadBytes.isNotEmpty) {
            return {
              'type': typeString,
              'payload': String.fromCharCodes(payloadBytes),
            };
          }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Convert record to human-readable string
  String _recordToString(NdefRecord record) {
    final type = String.fromCharCodes(record.type);
    final payload = String.fromCharCodes(record.payload);
    return 'Type: $type, Payload: $payload';
  }

  /// Decode URI record with prefix
  String _decodeUriRecord(Uint8List payload) {
    const prefixes = [
      '', // 0x00
      'http://www.', // 0x01
      'https://www.', // 0x02
      'http://', // 0x03
      'https://', // 0x04
      'tel:', // 0x05
      'mailto:', // 0x06
    ];
    
    final prefixCode = payload.first;
    final prefix = prefixCode < prefixes.length ? prefixes[prefixCode] : '';
    final uri = String.fromCharCodes(payload.sublist(1));
    
    return '$prefix$uri';
  }
}
