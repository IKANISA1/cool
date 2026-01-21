import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/location_service.dart';
import '../../../utilities/mobile_money/domain/country.dart';
import '../../../utilities/mobile_money/domain/mobile_money_repository.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/vehicle_category_card.dart';

/// Streamlined 2-3 step profile setup:
/// 1. Location Permission (auto-detect country)
/// 2. Role Selection
/// 3. Vehicle Selection (driver only)
/// → Home
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _locationService = LocationServiceImpl();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  String _selectedRole = '';
  String? _selectedVehicle;

  // Countries from Supabase
  List<Country> _countries = [];
  Country? _detectedCountry;
  bool _isLoadingCountries = true;

  // Location detection state
  bool _isDetectingLocation = false;
  bool _locationDetected = false;
  String? _locationError;

  bool get _isDriver =>
      _selectedRole == 'driver' || _selectedRole == 'both';
  int get _totalSteps => _isDriver ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Load countries from Supabase and detect location
    _loadCountries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// Load countries from Supabase
  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);

    try {
      final repository = getIt<MobileMoneyRepository>();
      final result = await repository.getCountries();

      result.fold(
        (error) {
          // On error, use default Rwanda
          setState(() {
            _isLoadingCountries = false;
            _countries = [];
            _detectedCountry = null;
          });
          // Still try to detect location
          _detectLocation();
        },
        (countries) {
          setState(() {
            _isLoadingCountries = false;
            _countries = countries;
            // Default to Rwanda
            _detectedCountry = countries.firstWhere(
              (c) => c.codeAlpha2 == 'RW',
              orElse: () => countries.first,
            );
          });
          // Then detect actual location
          _detectLocation();
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
        _countries = [];
      });
      _detectLocation();
    }
  }

  /// Get country by ISO code from loaded countries
  Country? _getCountryByCode(String? code) {
    if (code == null || _countries.isEmpty) return _detectedCountry;
    
    final upperCode = code.toUpperCase();
    return _countries.firstWhere(
      (c) => c.codeAlpha2.toUpperCase() == upperCode ||
             c.codeAlpha3.toUpperCase() == upperCode,
      orElse: () => _detectedCountry ?? _countries.first,
    );
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationError = null;
    });

    try {
      // Request permission
      final hasPermission = await _locationService.requestPermission();
      if (!hasPermission) {
        setState(() {
          _isDetectingLocation = false;
          _locationError = 'Location permission denied';
          _locationDetected = true; // Still allow to proceed with default
        });
        return;
      }

      // Get current position
      final position = await _locationService.getCurrentPosition();

      // Get country from coordinates
      final countryCode = await _locationService.getCountryCodeFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _isDetectingLocation = false;
        _locationDetected = true;
        _detectedCountry = _getCountryByCode(countryCode);
      });
    } catch (e) {
      setState(() {
        _isDetectingLocation = false;
        _locationError = 'Could not detect location';
        _locationDetected = true; // Still allow to proceed with default
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Location step
        return _locationDetected && !_isLoadingCountries;
      case 1: // Role selection
        return _selectedRole.isNotEmpty;
      case 2: // Vehicle (driver only)
        return _selectedVehicle != null;
      default:
        return false;
    }
  }

  void _completeProfile() {
    HapticFeedback.heavyImpact();

    // Use detected country code or default to RW
    final countryCode = _detectedCountry?.codeAlpha2 ?? 'RW';

    context.read<ProfileBloc>().add(
          CreateProfileRequested(
            name: '', // Name not required - can be set in profile later
            role: UserRole.fromString(_selectedRole),
            countryCode: countryCode,
            languages: [], // Languages can be set later
            vehicleCategory: _selectedVehicle != null
                ? VehicleCategory.fromString(_selectedVehicle)
                : null,
            whatsappNumber: null, // Deferred - will be required when offering/finding rides
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileCreated) {
              context.go('/home');
            } else if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ProfileLoading;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildProgressBar(theme),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildLocationStep(theme),
                        _buildRoleStep(theme),
                        if (_isDriver) _buildVehicleStep(theme),
                      ],
                    ),
                  ),
                  _buildBottomBar(theme, isLoading),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isActive = _currentStep >= index;
              final isCurrent = _currentStep == index;
              return Container(
                width: isCurrent ? 24 : 8,
                height: 8,
                margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.location_on_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Your Location',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We use your location to find nearby riders and drivers in your area.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Loading countries indicator
          if (_isLoadingCountries)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading countries...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Countries count indicator
            Center(
              child: Text(
                '${_countries.length} countries available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _locationDetected && _locationError == null
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
                  width: _locationDetected && _locationError == null ? 2 : 1,
                ),
              ),
              child: _isDetectingLocation
                  ? _buildDetectingState(theme)
                  : _locationDetected
                      ? _buildDetectedState(theme)
                      : _buildInitialState(theme),
            ),
          ],

          if (_locationError != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using ${_detectedCountry?.name ?? "Rwanda"} as default. You can change this later in settings.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Retry button if error
          if (_locationError != null && !_isDetectingLocation)
            Center(
              child: TextButton.icon(
                onPressed: _detectLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry detection'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectingState(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Detecting your location...',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedState(ThemeData theme) {
    final country = _detectedCountry;
    if (country == null) {
      return _buildInitialState(theme);
    }

    return Row(
      children: [
        Text(
          country.flagEmoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                country.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _locationError != null ? 'Default country' : 'Detected from GPS',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        if (_locationError == null)
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
          ),
      ],
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.location_off,
          size: 32,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Waiting for location...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'What would you like to do?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always change this later',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 40),

          // Role cards - minimal design
          _RoleCard(
            icon: Icons.directions_walk_rounded,
            title: 'Find Rides',
            subtitle: 'Search for available drivers and rides',
            isSelected: _selectedRole == 'passenger',
            onTap: () => setState(() => _selectedRole = 'passenger'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.directions_car_rounded,
            title: 'Offer Rides',
            subtitle: 'Share your vehicle with passengers',
            isSelected: _selectedRole == 'driver',
            onTap: () => setState(() => _selectedRole = 'driver'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Both',
            subtitle: 'Find and offer rides flexibly',
            isSelected: _selectedRole == 'both',
            onTap: () => setState(() => _selectedRole = 'both'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Select your vehicle',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What type of vehicle will you offer rides with?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: VehicleCategory.values.map((category) {
              return VehicleCategoryCard(
                category: category.name,
                label: category.displayName,
                icon: category.icon,
                isSelected: _selectedVehicle == category.name,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedVehicle = category.name);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isLoading) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: isLoading ? null : _previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: (_canProceed() && !isLoading) ? _nextStep : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      isLastStep ? 'Get Started' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal role selection card
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
