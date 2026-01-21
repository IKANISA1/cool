import 'package:equatable/equatable.dart';

class PaymentTransaction extends Equatable {
  final String id;
  final double amount;
  final String currency;
  final String email;
  final String reference;
  final String status;
  final DateTime timestamp;

  const PaymentTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.email,
    required this.reference,
    required this.status,
    required this.timestamp,
  });

  @override
  List<Object> get props => [id, amount, currency, email, reference, status, timestamp];
}
