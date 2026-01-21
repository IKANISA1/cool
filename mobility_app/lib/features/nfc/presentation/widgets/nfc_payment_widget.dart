import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nfc_bloc.dart';
import '../../data/services/nfc_service.dart';

/// Premium NFC Payment Widget with glassmorphism design
/// 
/// Features:
/// - Pulsing NFC icon animation during scanning
/// - Haptic feedback on success/error
/// - Gradient background with glass effect
/// - State-based UI (idle, scanning, success, error)
class NFCPaymentWidget extends StatefulWidget {
  final double amount;
  final String currency;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const NFCPaymentWidget({
    required this.amount,
    this.currency = 'RWF',
    this.onSuccess,
    this.onError,
    super.key,
  });

  @override
  State<NFCPaymentWidget> createState() => _NFCPaymentWidgetState();
}

class _NFCPaymentWidgetState extends State<NFCPaymentWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  bool _isScanning = false;
  late NFCBloc _nfcBloc;

  @override
  void initState() {
    super.initState();
    _nfcBloc = NFCBloc(NFCService.instance);
    
    // Pulse animation for scanning state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Success scale animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  void _startPayment() {
    setState(() => _isScanning = true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.mediumImpact();
    
    _nfcBloc.add(ProcessNFCPayment(
      amount: widget.amount,
      currency: widget.currency,
    ));
  }

  void _onPaymentSuccess() {
    _pulseController.stop();
    _successController.forward();
    HapticFeedback.heavyImpact();
    setState(() => _isScanning = false);
    widget.onSuccess?.call();
  }

  void _onPaymentError() {
    _pulseController.stop();
    HapticFeedback.vibrate();
    setState(() => _isScanning = false);
    widget.onError?.call();
  }

  void _reset() {
    _pulseController.reset();
    _successController.reset();
    _nfcBloc.add(StopNFCScan());
    setState(() => _isScanning = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _nfcBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _nfcBloc,
      child: BlocConsumer<NFCBloc, NFCState>(
        listener: (context, state) {
          if (state is NFCPaymentSuccess) {
            _onPaymentSuccess();
          } else if (state is NFCError) {
            _onPaymentError();
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getGradientColors(state),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _getPrimaryColor(state).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNFCIcon(state),
                    const SizedBox(height: 24),
                    _buildStatusText(state),
                    const SizedBox(height: 12),
                    _buildAmountDisplay(),
                    const SizedBox(height: 24),
                    _buildActionButton(state),
                    if (!Platform.isAndroid && state is NFCPaymentProcessing)
                      _buildIOSNote(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNFCIcon(NFCState state) {
    IconData icon;
    Color color;

    if (state is NFCPaymentSuccess) {
      icon = Icons.check_circle_outline_rounded;
      color = Colors.greenAccent;
    } else if (state is NFCError) {
      icon = Icons.error_outline_rounded;
      color = Colors.redAccent;
    } else {
      icon = Icons.nfc_rounded;
      color = Colors.white;
    }

    Widget iconWidget = AnimatedBuilder(
      animation: state is NFCPaymentSuccess ? _scaleAnimation : _pulseAnimation,
      builder: (context, child) {
        final scale = state is NFCPaymentSuccess
            ? _scaleAnimation.value
            : (_isScanning ? _pulseAnimation.value : 1.0);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 60,
          color: color,
        ),
      ),
    );

    // Add ripple effect when scanning
    if (_isScanning && state is NFCPaymentProcessing) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Outer ripple
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 140 + (_pulseAnimation.value - 1.0) * 100,
                height: 140 + (_pulseAnimation.value - 1.0) * 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.3 * (1 - (_pulseAnimation.value - 1.0) * 6.67),
                    ),
                    width: 2,
                  ),
                ),
              );
            },
          ),
          iconWidget,
        ],
      );
    }

    return iconWidget;
  }

  Widget _buildStatusText(NFCState state) {
    String title;
    String subtitle;

    if (state is NFCPaymentProcessing) {
      title = 'Hold Near Device';
      subtitle = 'Waiting for NFC card...';
    } else if (state is NFCPaymentSuccess) {
      title = 'Payment Successful';
      subtitle = state.result.transactionId ?? 'Transaction complete';
    } else if (state is NFCError) {
      title = 'Payment Failed';
      subtitle = state.message;
    } else {
      title = 'Tap to Pay';
      subtitle = 'Use NFC for quick payment';
    }

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            title,
            key: ValueKey(title),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '${widget.currency} ${widget.amount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionButton(NFCState state) {
    if (state is NFCPaymentProcessing) {
      return TextButton(
        onPressed: _reset,
        child: Text(
          'Cancel',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      );
    }

    if (state is NFCPaymentSuccess) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (state is NFCError) {
      return ElevatedButton(
        onPressed: _startPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Try Again',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _startPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: Colors.black26,
      ),
      child: const Text(
        'Start NFC Payment',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIOSNote() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'iOS: Read-only mode. Writing requires Android.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  List<Color> _getGradientColors(NFCState state) {
    if (state is NFCPaymentSuccess) {
      return [Colors.green.shade600, Colors.teal.shade600];
    } else if (state is NFCError) {
      return [Colors.red.shade600, Colors.orange.shade700];
    }
    return [Colors.blue.shade600, Colors.indigo.shade600];
  }

  Color _getPrimaryColor(NFCState state) {
    if (state is NFCPaymentSuccess) return Colors.green;
    if (state is NFCError) return Colors.red;
    return Colors.blue;
  }
}
