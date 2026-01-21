import 'package:flutter/material.dart';
import 'package:ridelink/core/theme/app_theme.dart';
import 'package:ridelink/shared/widgets/glass_components.dart';
import 'package:ridelink/features/home/presentation/screens/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _selectedRole = '';
  String _selectedVehicle = '';
  String _selectedCountry = '';
  final _nameController = TextEditingController();

  final List<String> _roles = ['Driver', 'Passenger'];
  final List<String> _vehicles = [
    'Moto Taxi',
    'Cab',
    'Liffan',
    'Truck',
    'Rent',
    'Other'
  ];
  final List<String> _countries = [
    'Rwanda',
    'Kenya',
    'Uganda',
    'Tanzania',
    'Burundi'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Name
                const Text(
                  'Your Name',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GlassTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                ),
                const SizedBox(height: 24),
                
                // Role Selection
                const Text(
                  'I am a...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GlassButton(
                          height: 56,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          onPressed: () {
                            setState(() => _selectedRole = role);
                          },
                          child: Text(
                            role,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF7B2CBF)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                // Vehicle Selection (if Driver)
                if (_selectedRole == 'Driver') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      final isSelected = _selectedVehicle == vehicle;
                      return GlassButton(
                        height: 56,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.1),
                        onPressed: () {
                          setState(() => _selectedVehicle = vehicle);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VehicleIcon(
                              vehicleType: vehicle,
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF7B2CBF)
                                  : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              vehicle,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF7B2CBF)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Country Selection
                const Text(
                  'Country',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry.isEmpty ? null : _selectedCountry,
                      hint: const Text(
                        'Select Country',
                        style: TextStyle(color: Colors.white60),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1A1A2E), // Match surface color
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      items: _countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCountry = value ?? '');
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Continue Button
                GlassButton(
                  height: 56,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
