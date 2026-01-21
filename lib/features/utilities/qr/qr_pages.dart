import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/glassmorphic_card.dart';
import '../qr/qr_service.dart';

/// QR Scanner page with camera preview
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _hasScanned = false;
  QrPayload? _scannedPayload;
  String? _rawData;

  void _onScanned(String data, QrPayload? payload) {
    HapticFeedback.heavyImpact();
    setState(() {
      _hasScanned = true;
      _rawData = data;
      _scannedPayload = payload;
    });
  }

  void _handleResult() {
    if (_scannedPayload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown QR code format')),
      );
      return;
    }

    switch (_scannedPayload!) {
      case ProfileQrPayload(userId: final userId, name: final name):
        Navigator.pushReplacementNamed(
          context,
          '/user-profile',
          arguments: {'userId': userId, 'name': name},
        );

      case RequestQrPayload(requestId: final requestId):
        Navigator.pushReplacementNamed(
          context,
          '/request/$requestId',
        );

      case TripQrPayload(tripId: final tripId):
        Navigator.pushReplacementNamed(
          context,
          '/schedule/$tripId',
        );

      case PaymentQrPayload(userId: final userId, amount: final amount, currency: final currency):
        Navigator.pushReplacementNamed(
          context,
          '/pay',
          arguments: {
            'userId': userId,
            'amount': amount,
            'currency': currency,
          },
        );
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _scannedPayload = null;
      _rawData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: _hasScanned ? _buildResult(theme) : _buildScanner(theme),
    );
  }

  Widget _buildScanner(ThemeData theme) {
    return Stack(
      children: [
        QrScannerWidget(
          onScanned: _onScanned,
          onError: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera error. Please check permissions.')),
            );
          },
        ),
        // Glassmorphic Overlay
        Positioned.fill(
          child: Stack(
            children: [
              // Darken background outside scan area
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.6),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scanning Frame with Glow
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Instructions
              Positioned(
                bottom: 100,
                left: 24,
                right: 24,
                child: GlassmorphicCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Align QR code within the frame',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _scannedPayload != null
                  ? Icons.check_circle
                  : Icons.qr_code_scanner,
              size: 80,
              color: _scannedPayload != null
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _scannedPayload != null ? 'QR Code Scanned!' : 'Unknown Format',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPayloadInfo(theme),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScanner,
                    child: const Text('Scan Again'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _scannedPayload != null ? _handleResult : null,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadInfo(ThemeData theme) {
    if (_scannedPayload == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.help_outline),
              const SizedBox(height: 8),
              Text(
                'Unrecognized QR code',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _rawData ?? 'No data',
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (_scannedPayload!) {
          ProfileQrPayload(userId: final userId, name: final name) => Column(
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  name ?? 'User',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Profile ID: ${userId.substring(0, 8)}...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          RequestQrPayload(requestId: final requestId) => Column(
              children: [
                const Icon(Icons.handshake, size: 48, color: Colors.blue),
                const SizedBox(height: 12),
                Text(
                  'Ride Request',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Request ID: ${requestId.substring(0, 8)}...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          TripQrPayload(tripId: final tripId) => Column(
              children: [
                const Icon(Icons.schedule, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                Text(
                  'Scheduled Trip',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Trip ID: ${tripId.substring(0, 8)}...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          PaymentQrPayload(amount: final amount, currency: final currency) =>
            Column(
              children: [
                const Icon(Icons.payment, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'Payment Request',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$amount $currency',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
        },
      ),
    );
  }
}

/// Page for displaying a QR code
class QrDisplayPage extends StatelessWidget {
  final String title;
  final String data;
  final String? subtitle;

  const QrDisplayPage({
    super.key,
    required this.title,
    required this.data,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share QR code image
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: QrService.buildQrCode(
                    data: data,
                    size: 240,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan this code to connect',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
