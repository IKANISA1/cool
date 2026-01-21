import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_trip_request.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';

/// Page to confirm and finalize an AI-parsed trip
///
/// Allows user to:
/// - Review parsed trip details
/// - Edit any fields before proceeding
/// - Confirm and search for drivers/passengers
class AITripConfirmPage extends StatefulWidget {
  /// The parsed trip request
  final AITripRequest tripRequest;

  const AITripConfirmPage({
    super.key,
    required this.tripRequest,
  });

  @override
  State<AITripConfirmPage> createState() => _AITripConfirmPageState();
}

class _AITripConfirmPageState extends State<AITripConfirmPage> {
  late TextEditingController _destinationController;
  late TextEditingController _originController;
  late TextEditingController _notesController;
  
  String _selectedTimeType = 'now';
  DateTime? _scheduledTime;
  String? _vehiclePreference;
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(
      text: widget.tripRequest.destination?.name ?? '',
    );
    _originController = TextEditingController(
      text: widget.tripRequest.origin?.name ?? '',
    );
    _notesController = TextEditingController(
      text: widget.tripRequest.notes ?? '',
    );
    _selectedTimeType = widget.tripRequest.timeType;
    _scheduledTime = widget.tripRequest.scheduledTime;
    _vehiclePreference = widget.tripRequest.vehiclePreference;
    _passengerCount = widget.tripRequest.passengerCount ?? 1;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _originController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _confirmTrip() {
    HapticFeedback.mediumImpact();

    // Create updated trip request
    final updatedRequest = widget.tripRequest.copyWith(
      destination: TripLocation(name: _destinationController.text.trim()),
      origin: _originController.text.isNotEmpty
          ? TripLocation(name: _originController.text.trim())
          : null,
      timeType: _selectedTimeType,
      scheduledTime: _scheduledTime,
      vehiclePreference: _vehiclePreference,
      passengerCount: _passengerCount,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isValid: true,
    );

    // Emit the updated request and navigate to discovery
    context.read<AIAssistantBloc>().add(EditParsedRequest(updatedRequest));
    context.read<AIAssistantBloc>().add(const ConfirmTrip());

    // Navigate to discovery with trip context
    Navigator.pushReplacementNamed(
      context,
      '/discovery',
      arguments: updatedRequest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Trip'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination field
                    _SectionHeader(
                      icon: Icons.location_on,
                      title: 'Destination',
                      required: true,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _destinationController,
                      hint: 'Where are you going?',
                      prefixIcon: Icons.place,
                    ),

                    const SizedBox(height: 24),

                    // Origin field (optional)
                    _SectionHeader(
                      icon: Icons.trip_origin,
                      title: 'Pickup Location',
                      subtitle: 'Optional - defaults to current location',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _originController,
                      hint: 'Current location',
                      prefixIcon: Icons.my_location,
                    ),

                    const SizedBox(height: 24),

                    // Time selection
                    _SectionHeader(
                      icon: Icons.access_time,
                      title: 'When',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSelector(theme),

                    const SizedBox(height: 24),

                    // Vehicle preference
                    _SectionHeader(
                      icon: Icons.directions_car,
                      title: 'Vehicle Type',
                    ),
                    const SizedBox(height: 12),
                    _buildVehicleSelector(theme),

                    const SizedBox(height: 24),

                    // Passengers
                    _SectionHeader(
                      icon: Icons.people,
                      title: 'Passengers',
                    ),
                    const SizedBox(height: 12),
                    _buildPassengerSelector(theme),

                    const SizedBox(height: 24),

                    // Notes
                    _SectionHeader(
                      icon: Icons.note,
                      title: 'Additional Notes',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _notesController,
                      hint: 'Any special requirements?',
                      prefixIcon: Icons.edit_note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _destinationController.text.isNotEmpty
                      ? _confirmTrip
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Find Rides',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTimeSelector(ThemeData theme) {
    final options = [
      ('now', 'Right Now', Icons.flash_on),
      ('today', 'Today', Icons.today),
      ('tomorrow', 'Tomorrow', Icons.event),
      ('specific', 'Pick Time', Icons.schedule),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = _selectedTimeType == opt.$1;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(opt.$3, size: 16),
                  const SizedBox(width: 4),
                  Text(opt.$2),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTimeType = opt.$1;
                  if (opt.$1 == 'specific') {
                    _showDateTimePicker();
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedTimeType == 'specific' && _scheduledTime != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showDateTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _formatDateTime(_scheduledTime!),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVehicleSelector(ThemeData theme) {
    final vehicles = [
      ('moto', 'Moto', Icons.two_wheeler),
      ('cab', 'Cab', Icons.local_taxi),
      ('liffan', 'Tuk-Tuk', Icons.electric_rickshaw),
      ('truck', 'Truck', Icons.local_shipping),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vehicles.map((v) {
        final isSelected = _vehiclePreference == v.$1;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(v.$3, size: 16),
              const SizedBox(width: 4),
              Text(v.$2),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            HapticFeedback.selectionClick();
            setState(() {
              _vehiclePreference = selected ? v.$1 : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPassengerSelector(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          onPressed: _passengerCount > 1
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() => _passengerCount--);
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$_passengerCount',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _passengerCount < 10
              ? () {
                  HapticFeedback.selectionClick();
                  setState(() => _passengerCount++);
                }
              : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: 8),
        Text(
          _passengerCount == 1 ? 'passenger' : 'passengers',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _scheduledTime ?? DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    String dayPart;

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      dayPart = 'Today';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day + 1) {
      dayPart = 'Tomorrow';
    } else {
      dayPart = '${dt.day}/${dt.month}/${dt.year}';
    }

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dayPart at $hour:$minute';
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool required;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (required)
                  Text(
                    ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
