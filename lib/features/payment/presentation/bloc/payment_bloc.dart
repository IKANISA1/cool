import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/process_payment.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository paymentRepository;
  final ProcessPayment processPayment;

  PaymentBloc({
    required this.paymentRepository,
    required this.processPayment,
  }) : super(PaymentInitial()) {
    on<InitializePayment>(_onInitializePayment);
    on<ProcessPaymentEvent>(_onProcessPayment);
  }

  Future<void> _onInitializePayment(
    InitializePayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final result = await paymentRepository.initializeTransaction(
      email: event.email,
      amount: event.amount,
    );

    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (accessCode) => emit(PaymentInitialized(
        accessCode: accessCode,
        reference: 'REF_${DateTime.now().millisecondsSinceEpoch}',
      )),
    );
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    final result = await processPayment(ProcessPaymentParams(
      context: event.context,
      amount: event.amount,
      email: event.email,
      accessCode: event.accessCode,
      reference: event.reference,
    ));

    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (transaction) => emit(PaymentSuccess(transaction)),
    );
  }
}
