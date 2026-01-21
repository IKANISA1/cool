import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/error/failures.dart';

import '../entities/payment_transaction.dart';
import '../repositories/payment_repository.dart';

class ProcessPayment {
  final PaymentRepository repository;

  ProcessPayment(this.repository);

  Future<Either<Failure, PaymentTransaction>> call(ProcessPaymentParams params) async {
    return await repository.processPayment(
      context: params.context,
      amount: params.amount,
      email: params.email,
      accessCode: params.accessCode,
      reference: params.reference,
    );
  }
}

class ProcessPaymentParams extends Equatable {
  final BuildContext context;
  final double amount;
  final String email;
  final String accessCode;
  final String reference;

  const ProcessPaymentParams({
    required this.context,
    required this.amount,
    required this.email,
    required this.accessCode,
    required this.reference,
  });

  @override
  List<Object> get props => [context, amount, email, accessCode, reference];
}
