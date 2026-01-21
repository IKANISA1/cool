import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';
import '../../../../core/error/exceptions.dart';
import '../models/payment_transaction_model.dart';

abstract class PaymentRemoteDataSource {
  Future<String> initializeTransaction({required String email, required double amount});
  Future<PaymentTransactionModel> chargeCard({
    required BuildContext context,
    required String accessCode,
    required String reference,
    required String email,
    required double amount,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl();

  String get _publicKey => dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
  String get _secretKey => dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';

  @override
  Future<String> initializeTransaction({required String email, required double amount}) async {
    // Generate a unique reference
    return 'REF_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<PaymentTransactionModel> chargeCard({
    required BuildContext context,
    required String accessCode,
    required String reference,
    required String email,
    required double amount,
  }) async {
    bool paymentSuccessful = false;
    String? paymentReference;

    try {
      await FlutterPaystackPlus.openPaystackPopup(
        publicKey: _publicKey,
        secretKey: _secretKey,
        context: context,
        amount: (amount * 100).toInt().toString(), // Amount in kobo/cents
        currency: 'NGN',
        customerEmail: email, // Correct parameter name
        reference: reference,
        callBackUrl: 'https://example.com/callback', // Required for mobile
        onClosed: () {
          // Payment popup closed without completion
        },
        onSuccess: () {
          paymentSuccessful = true;
          paymentReference = reference;
        },
      );
    } catch (e) {
      throw ServerException(message: 'Payment failed: ${e.toString()}');
    }

    if (paymentSuccessful) {
      return PaymentTransactionModel(
        id: paymentReference ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: 'NGN',
        email: email,
        reference: paymentReference ?? reference,
        status: 'success',
        timestamp: DateTime.now(),
      );
    } else {
      throw ServerException(message: 'Payment was cancelled or failed');
    }
  }
}
