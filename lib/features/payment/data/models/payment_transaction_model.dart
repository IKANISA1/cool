import '../../domain/entities/payment_transaction.dart';

class PaymentTransactionModel extends PaymentTransaction {
  const PaymentTransactionModel({
    required super.id,
    required super.amount,
    required super.currency,
    required super.email,
    required super.reference,
    required super.status,
    required super.timestamp,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      email: json['email'],
      reference: json['reference'],
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'email': email,
      'reference': reference,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
