import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/profile.dart';
import '../widgets/vehicle_category_card.dart';

/// Dedicated vehicle selection page (alternative flow)
class VehicleSelectionPage extends StatefulWidget {
  final VehicleCategory? initialSelection;
  final ValueChanged<VehicleCategory> onVehicleSelected;

  const VehicleSelectionPage({
    super.key,
    this.initialSelection,
    required this.onVehicleSelected,
  });

  @override
  State<VehicleSelectionPage> createState() => _VehicleSelectionPageState();
}

class _VehicleSelectionPageState extends State<VehicleSelectionPage> {
  VehicleCategory? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Vehicle'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you drive?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your primary vehicle type',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: VehicleCategory.values.map((category) {
                    return VehicleCategoryCard(
                      category: category.name,
                      label: category.displayName,
                      icon: category.icon,
                      isSelected: _selectedVehicle == category,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _selectedVehicle = category);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedVehicle != null
                      ? () {
                          HapticFeedback.heavyImpact();
                          widget.onVehicleSelected(_selectedVehicle!);
                          Navigator.of(context).pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirm Selection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
