import 'package:flutter/material.dart';

import '../../../data/models/station_marker.dart';

/// Pricing section showing swap/charge costs and payment methods
class PricingSection extends StatelessWidget {
  final StationMarker station;
  final String stationType;

  const PricingSection({
    super.key,
    required this.station,
    required this.stationType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBatterySwap = stationType == 'battery_swap';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.payments_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Pricing',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Pricing card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Price row
              if (isBatterySwap) _buildBatterySwapPricing(theme, colorScheme)
              else _buildEVChargingPricing(theme, colorScheme),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Payment methods
              _buildPaymentMethods(theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatterySwapPricing(ThemeData theme, ColorScheme colorScheme) {
    final price = station.details['price_per_swap'] as double?;
    final currency = station.details['currency'] as String? ?? 'RWF';
    final swapTime = station.details['swap_time_minutes'] as int?;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Per Swap',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price != null ? '$currency ${price.toStringAsFixed(0)}' : 'Contact station',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        if (swapTime != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
                Text(
                  '~$swapTime min',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEVChargingPricing(ThemeData theme, ColorScheme colorScheme) {
    final isFree = station.details['is_free'] as bool? ?? false;
    final pricingInfo = station.details['pricing_info'] as Map<String, dynamic>?;
    final maxPower = station.details['max_power_kw'] as double?;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Charging Cost',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            if (isFree)
              Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    'FREE',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              )
            else
              Text(
                pricingInfo != null
                    ? '${pricingInfo['currency'] ?? 'RWF'} ${pricingInfo['price_per_kwh'] ?? 0}/kWh'
                    : 'Contact station',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
        if (maxPower != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Text(
                  '${maxPower.toInt()} kW',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentMethods(ThemeData theme, ColorScheme colorScheme) {
    final paymentMethods = station.details['payment_methods'] as List? ?? 
        ['cash', 'momo', 'card'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Methods',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: paymentMethods.map<Widget>((method) {
            return _buildPaymentChip(method.toString(), theme, colorScheme);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String method, ThemeData theme, ColorScheme colorScheme) {
    IconData icon;
    String label;

    switch (method.toLowerCase()) {
      case 'cash':
        icon = Icons.money;
        label = 'Cash';
        break;
      case 'momo':
      case 'mobile_money':
        icon = Icons.phone_android;
        label = 'Mobile Money';
        break;
      case 'card':
      case 'credit_card':
        icon = Icons.credit_card;
        label = 'Card';
        break;
      case 'airtel':
        icon = Icons.phone_android;
        label = 'Airtel Money';
        break;
      default:
        icon = Icons.payment;
        label = method;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
