import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_transaction.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentInitialized extends PaymentState {
  final String accessCode;
  final String reference;

  const PaymentInitialized({required this.accessCode, required this.reference});

  @override
  List<Object> get props => [accessCode, reference];
}

class PaymentSuccess extends PaymentState {
  final PaymentTransaction transaction;

  const PaymentSuccess(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class PaymentFailure extends PaymentState {
  final String message;

  const PaymentFailure(this.message);

  @override
  List<Object> get props => [message];
}
