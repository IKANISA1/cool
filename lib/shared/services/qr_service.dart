// ============================================================================
// QR SERVICE - shared/services/qr_service.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
// Note: Dependencies must be added to pubspec.yaml: qr_flutter, qr_code_scanner

class QRService {
  /// Generate QR code widget
  Widget generateQRCode({
    required String data,
    double size = 200,
    Color? color,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: color ?? Colors.black,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: color ?? Colors.black,
      ),
    );
  }

  /// Generate profile QR data
  String generateProfileQR({
    required String userId,
    required String name,
    required String role,
  }) {
    return 'ridelink://profile?user_id=$userId&name=$name&role=$role';
  }

  /// Generate payment QR data (MoMo format)
  String generatePaymentQR({
    required String phone,
    required double amount,
    String? reference,
  }) {
    // EMVCo format for mobile money
    return 'MOMO:$phone:$amount:${reference ?? ""}';
  }

  /// Parse scanned QR data
  Map<String, dynamic> parseQRData(String data) {
    if (data.startsWith('ridelink://')) {
      final uri = Uri.parse(data);
      return {
        'type': 'profile',
        'data': uri.queryParameters,
      };
    } else if (data.startsWith('MOMO:')) {
      final parts = data.split(':');
      return {
        'type': 'payment',
        'phone': parts[1],
        'amount': double.tryParse(parts.length > 2 ? parts[2] : '0.0') ?? 0.0,
        'reference': parts.length > 3 ? parts[3] : null,
      };
    }
    return {'type': 'unknown', 'data': data};
  }
}
