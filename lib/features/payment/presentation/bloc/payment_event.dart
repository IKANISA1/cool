import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class InitializePayment extends PaymentEvent {
  final String email;
  final double amount;

  const InitializePayment({required this.email, required this.amount});

  @override
  List<Object> get props => [email, amount];
}

class ProcessPaymentEvent extends PaymentEvent {
  final BuildContext context;
  final String email;
  final double amount;
  final String accessCode;
  final String reference;

  const ProcessPaymentEvent({
    required this.context,
    required this.email,
    required this.amount,
    required this.accessCode,
    required this.reference,
  });

  @override
  List<Object> get props => [context, email, amount, accessCode, reference];
}
