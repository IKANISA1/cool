import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../bloc/nfc_bloc.dart';
import '../../data/services/nfc_service.dart';

/// NFC Reader Modal for scanning NFC tags
/// 
/// Features:
/// - Lottie animation during scanning
/// - Parsed NDEF data display
/// - Haptic feedback on scan success/failure
/// - Support for both Android and iOS
class NFCReaderModal extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(NFCReadResult)? onDataRead;
  final Duration? timeout;

  const NFCReaderModal({
    this.onSuccess,
    this.onDataRead,
    this.timeout,
    super.key,
  });

  /// Show the reader modal as a bottom sheet
  static Future<NFCReadResult?> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    Function(NFCReadResult)? onDataRead,
    Duration? timeout,
  }) {
    return showModalBottomSheet<NFCReadResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NFCReaderModal(
        onSuccess: onSuccess,
        onDataRead: onDataRead,
        timeout: timeout,
      ),
    );
  }

  @override
  State<NFCReaderModal> createState() => _NFCReaderModalState();
}

class _NFCReaderModalState extends State<NFCReaderModal> {
  late NFCBloc _nfcBloc;
  NFCReadResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _nfcBloc = NFCBloc(NFCService.instance);
    // Start scanning immediately
    _nfcBloc.add(StartNFCScan());
  }

  void _onScanSuccess(NFCReadResult result) {
    HapticFeedback.heavyImpact();
    _lastResult = result;
    widget.onSuccess?.call();
    widget.onDataRead?.call(result);
  }

  void _onScanError() {
    HapticFeedback.vibrate();
  }

  void _retry() {
    _nfcBloc.add(StartNFCScan());
  }

  @override
  void dispose() {
    _nfcBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _nfcBloc,
      child: BlocConsumer<NFCBloc, NFCState>(
        listener: (context, state) {
          if (state is NFCReadSuccess) {
            _onScanSuccess(state.result);
          } else if (state is NFCError) {
            _onScanError();
          }
        },
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandle(),
                  const SizedBox(height: 32),
                  _buildContent(state),
                  const SizedBox(height: 24),
                  _buildActions(state),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent(NFCState state) {
    if (state is NFCScanning) {
      return _buildScanningUI();
    } else if (state is NFCReadSuccess) {
      return _buildSuccessUI(state.result);
    } else if (state is NFCScanned) {
      // Legacy support
      return _buildLegacyScannedUI(state);
    } else if (state is NFCError) {
      return _buildErrorUI(state.message);
    }
    return _buildScanningUI();
  }

  Widget _buildScanningUI() {
    return Column(
      children: [
        Lottie.asset(
          'assets/lottie/nfc_scan.json',
          width: 150,
          height: 150,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.nfc,
              size: 60,
              color: Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ready to Scan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hold your device near the NFC tag',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessUI(NFCReadResult result) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Scan Successful',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (result.tagId != null) ...[
          const SizedBox(height: 16),
          _buildDataRow('Tag ID', result.tagId!),
        ],
        if (result.ndefData != null && result.ndefData!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNdefDataDisplay(result.ndefData!),
        ],
      ],
    );
  }

  Widget _buildLegacyScannedUI(NFCScanned state) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Tag Detected',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'NFC tag discovered',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorUI(String message) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Scan Failed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNdefDataDisplay(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NDEF Data',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(NFCState state) {
    if (state is NFCScanning) {
      return TextButton(
        onPressed: () {
          _nfcBloc.add(StopNFCScan());
          Navigator.pop(context);
        },
        child: Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      );
    }

    if (state is NFCReadSuccess || state is NFCScanned) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Scan Again'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _lastResult),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      );
    }

    if (state is NFCError) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
