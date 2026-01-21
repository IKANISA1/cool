import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mobile_money_service.dart';

/// Mobile money payment page
class PaymentPage extends StatefulWidget {
  final String? recipientId;
  final double? initialAmount;
  final String? currency;

  const PaymentPage({
    super.key,
    this.recipientId,
    this.initialAmount,
    this.currency,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _mobileMoneyService = MobileMoneyService();
  
  MobileMoneyProvider? _selectedProvider;
  bool _isProcessing = false;
  PaymentResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    final provider = _mobileMoneyService.detectProvider(value);
    if (provider != _selectedProvider) {
      setState(() => _selectedProvider = provider);
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);

    final result = await _mobileMoneyService.initiatePayment(
      phone: _phoneController.text.trim(),
      merchantCode: widget.recipientId ?? 'DEFAULT',
      amount: double.parse(_amountController.text.trim()),
      currency: widget.currency ?? 'RWF',
    );

    setState(() {
      _isProcessing = false;
      _result = result;
    });
  }

  void _resetPayment() {
    setState(() {
      _result = null;
      _phoneController.clear();
      _amountController.clear();
      _selectedProvider = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Money'),
      ),
      body: SafeArea(
        child: _result != null
            ? _buildResult(theme)
            : _buildForm(theme),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider badges
            _buildProviderBadges(theme),
            const SizedBox(height: 24),

            // Phone number
            Text(
              'Phone Number',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '078 XXX XXXX',
                prefixIcon: const Icon(Icons.phone),
                prefixText: '+250 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _selectedProvider != null
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildProviderChip(_selectedProvider!, theme),
                      )
                    : null,
              ),
              onChanged: _onPhoneChanged,
              validator: (v) {
                if (v?.isEmpty == true) return 'Required';
                if (_selectedProvider == null) return 'Invalid phone number';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Amount
            Text(
              'Amount',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1000',
                prefixIcon: const Icon(Icons.payments),
                suffixText: widget.currency ?? 'RWF',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Required';
                final amount = double.tryParse(v!);
                if (amount == null || amount <= 0) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Quick amount buttons
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000].map((amount) {
                return ActionChip(
                  label: Text('$amount'),
                  onPressed: () {
                    _amountController.text = amount.toString();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProcessing ? 'Processing...' : 'Send Payment'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBadges(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MobileMoneyProvider.values.map((provider) {
        final isSelected = _selectedProvider == provider;
        final isAvailable = provider != MobileMoneyProvider.mPesa;

        return Opacity(
          opacity: isAvailable ? 1 : 0.5,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  Icons.phone_android,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.shortName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProviderChip(MobileMoneyProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        provider.shortName,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            switch (_result!) {
              PaymentSuccess(transactionId: final txId) => Column(
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Payment Successful!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Transaction: ${txId.substring(0, 12)}...'),
                  ],
                ),
              PaymentPending(transactionId: final txId, message: final msg) =>
                Column(
                  children: [
                    const Icon(Icons.phone_android, size: 80, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm on Phone',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      msg ?? 'Please confirm the payment on your phone',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transaction: ${txId.substring(0, 12)}...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              PaymentFailure(code: _, message: final msg) => Column(
                  children: [
                    const Icon(Icons.error, size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Payment Failed',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(msg, textAlign: TextAlign.center),
                  ],
                ),
            },
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resetPayment,
                child: const Text('New Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
