import 'package:flutter/material.dart';
import 'package:ridelink/shared/services/nfc_service.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

class NFCPaymentScreen extends StatefulWidget {
  final double amount;
  
  const NFCPaymentScreen({super.key, required this.amount});

  @override
  State<NFCPaymentScreen> createState() => _NFCPaymentScreenState();
}

class _NFCPaymentScreenState extends State<NFCPaymentScreen> {
  final NFCService _nfcService = NFCService();
  String _status = 'Ready to Scan';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }
  
  Future<void> _checkNfcAvailability() async {
    bool isAvailable = await _nfcService.isAvailable();
    if (!isAvailable) {
       setState(() => _status = 'NFC not available on this device');
    } else {
      _startNfcScan();
    }
  }
  
  Future<void> _startNfcScan() async {
     setState(() {
       _status = 'Hold device near reader...';
     });
     
     // In a real flow, checking for a payment terminal tag
     // Here we just simulate reading any tag as a success
     String? tagData = await _nfcService.startNFCRead();
     
     if (tagData != null) {
       _processPayment(tagData);
     } else {
        setState(() => _status = 'Scan failed or cancelled. Try again.');
     }
  }
  
  Future<void> _processPayment(String data) async {
    setState(() {
      _isProcessing = true;
      _status = 'Processing Payment...';
    });
    
    // Haptic feedback
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 200);
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _status = 'Payment Successful!';
      });
      // Double success vibe
       if (await Vibration.hasVibrator()) {
         Vibration.vibrate(pattern: [0, 100, 100, 100]);
       }
       
       await Future.delayed(const Duration(seconds: 1));
       if (mounted) Navigator.of(context).pop(true);
    }
  }
  
  @override
  void dispose() {
    _nfcService.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Tap to Pay', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Lottie "contactless" animation
            // In a real app setup, ensure assets/lottie/nfc_scan.json exists
            SizedBox(
              height: 250,
              width: 250,
              child: Lottie.asset(
                'assets/lottie/nfc_scan.json', // Ensure you have this asset or replace with Icon
                errorBuilder: (context, error, stackTrace) {
                   return const Icon(Icons.nfc, size: 150, color: Colors.cyanAccent);
                }
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'RWF ${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
             Text(
              _status,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
          ],
        ),
      ),
    );
  }
}
