import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:logging/logging.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Service for QR code generation and scanning
class QrService {
  static final _log = Logger('QrService');

  /// Generate QR code data for a user profile
  static String encodeProfileQr(String userId, String name) {
    return 'mobility://profile/$userId?name=${Uri.encodeComponent(name)}';
  }

  /// Generate QR code data for a ride request
  static String encodeRideRequestQr({
    required String requestId,
    required String fromUserId,
    required String toUserId,
  }) {
    return 'mobility://request/$requestId?from=$fromUserId&to=$toUserId';
  }

  /// Generate QR code data for a scheduled trip
  static String encodeTripQr(String tripId) {
    return 'mobility://trip/$tripId';
  }

  /// Generate QR code data for a payment
  static String encodePaymentQr({
    required String userId,
    required double amount,
    required String currency,
    String? reference,
  }) {
    final ref = reference ?? DateTime.now().millisecondsSinceEpoch.toString();
    return 'mobility://pay/$userId?amount=$amount&currency=$currency&ref=$ref';
  }

  /// Parse QR code data
  static QrPayload? parseQrData(String data) {
    try {
      final uri = Uri.parse(data);
      if (uri.scheme != 'mobility') return null;

      switch (uri.host) {
        case 'profile':
          final userId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          final name = uri.queryParameters['name'];
          if (userId != null) {
            return QrPayload.profile(userId: userId, name: name);
          }
          break;

        case 'request':
          final requestId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          final fromUserId = uri.queryParameters['from'];
          final toUserId = uri.queryParameters['to'];
          if (requestId != null) {
            return QrPayload.request(
              requestId: requestId,
              fromUserId: fromUserId,
              toUserId: toUserId,
            );
          }
          break;

        case 'trip':
          final tripId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          if (tripId != null) {
            return QrPayload.trip(tripId: tripId);
          }
          break;

        case 'pay':
          final userId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
          final amount = double.tryParse(uri.queryParameters['amount'] ?? '');
          final currency = uri.queryParameters['currency'];
          final reference = uri.queryParameters['ref'];
          if (userId != null && amount != null && currency != null) {
            return QrPayload.payment(
              userId: userId,
              amount: amount,
              currency: currency,
              reference: reference,
            );
          }
          break;
      }
    } catch (e) {
      _log.warning('Failed to parse QR data: $e');
    }
    return null;
  }

  /// Create a QR code widget for display
  static Widget buildQrCode({
    required String data,
    double size = 200,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      padding: padding,
    );
  }

  /// Capture QR code as image bytes (for sharing)
  static Future<Uint8List?> captureQrAsImage(GlobalKey qrKey) async {
    try {
      final boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _log.warning('Failed to capture QR image: $e');
      return null;
    }
  }
}

/// QR Scanner widget that uses camera
class QrScannerWidget extends StatefulWidget {
  final void Function(String data, QrPayload? payload) onScanned;
  final VoidCallback? onError;

  const QrScannerWidget({
    super.key,
    required this.onScanned,
    this.onError,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _hasScanned = true;
      final data = barcode!.rawValue!;
      final payload = QrService.parseQrData(data);
      widget.onScanned(data, payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
    );
  }
}

/// Parsed QR payload
sealed class QrPayload {
  const QrPayload();

  factory QrPayload.profile({required String userId, String? name}) = ProfileQrPayload;
  factory QrPayload.request({
    required String requestId,
    String? fromUserId,
    String? toUserId,
  }) = RequestQrPayload;
  factory QrPayload.trip({required String tripId}) = TripQrPayload;
  factory QrPayload.payment({
    required String userId,
    required double amount,
    required String currency,
    String? reference,
  }) = PaymentQrPayload;
}

class ProfileQrPayload extends QrPayload {
  final String userId;
  final String? name;

  const ProfileQrPayload({required this.userId, this.name});
}

class RequestQrPayload extends QrPayload {
  final String requestId;
  final String? fromUserId;
  final String? toUserId;

  const RequestQrPayload({
    required this.requestId,
    this.fromUserId,
    this.toUserId,
  });
}

class TripQrPayload extends QrPayload {
  final String tripId;

  const TripQrPayload({required this.tripId});
}

class PaymentQrPayload extends QrPayload {
  final String userId;
  final double amount;
  final String currency;
  final String? reference;

  const PaymentQrPayload({
    required this.userId,
    required this.amount,
    required this.currency,
    this.reference,
  });
}
