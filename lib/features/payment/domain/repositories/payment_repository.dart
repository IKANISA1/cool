import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_transaction.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaymentTransaction>> processPayment({
    required BuildContext context,
    required double amount,
    required String email,
    required String accessCode,
    required String reference,
  });

  Future<Either<Failure, String>> initializeTransaction({
    required String email,
    required double amount,
  });
}
