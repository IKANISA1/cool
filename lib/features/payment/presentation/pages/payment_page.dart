import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../widgets/payment_method_selector.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final String email;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.email,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedMethod = 'mobile_money';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PaymentBloc>(
      create: (context) {
        final PaymentBloc bloc = GetIt.instance<PaymentBloc>();
        bloc.add(InitializePayment(email: widget.email, amount: widget.amount));
        return bloc;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BlocConsumer<PaymentBloc, PaymentState>(
            listener: (context, state) {
              if (state is PaymentSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment Successful: ${state.transaction.reference}')),
                );
                Navigator.of(context).pop(true);
              } else if (state is PaymentFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.message}')),
                );
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Amount Card
                        GlassmorphicCard(
                          width: double.infinity,
                          height: 120,
                          borderRadius: 20,
                          blur: 20,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'RFC ${widget.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Method Selector
                        PaymentMethodSelector(
                          selectedMethod: _selectedMethod,
                          onMethodSelected: (method) {
                            setState(() {
                              _selectedMethod = method;
                            });
                          },
                        ),
                        const SizedBox(height: 48),

                        // Pay Button
                        GestureDetector(
                          onTap: state is PaymentLoading
                              ? null
                              : () {
                                  if (state is PaymentInitialized) {
                                    context.read<PaymentBloc>().add(ProcessPaymentEvent(
                                          context: context,
                                          email: widget.email,
                                          amount: widget.amount,
                                          accessCode: state.accessCode,
                                          reference: state.reference,
                                        ));
                                  } else {
                                    // Retry initialization logic if needed or handle generic pay
                                  }
                                },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4ECCA3), Color(0xFF45B08C)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ECCA3).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Center(
                              child: state is PaymentLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
