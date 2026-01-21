import 'package:flutter/material.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMethodCard(
                context,
                id: 'card',
                title: 'Card',
                icon: Icons.credit_card,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMethodCard(
                context,
                id: 'mobile_money',
                title: 'Mobile Money',
                icon: Icons.smartphone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = selectedMethod == id;
    
    return GestureDetector(
      onTap: () => onMethodSelected(id),
      child: GradientGlassmorphicCard(
        borderRadius: 16,
        blur: 20,
        gradientColors: isSelected
            ? [
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.1),
              ]
            : [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
        child: SizedBox(
          width: double.infinity,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  size: 16,
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
