import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/bloc/profile_state.dart';
import '../../features/utilities/mobile_money/domain/country.dart';
import '../../features/utilities/mobile_money/domain/mobile_money_repository.dart';

/// Bottom sheet to collect WhatsApp number when required for ride actions
/// Shows when user tries to offer/find rides without WhatsApp configured
class WhatsAppRequiredSheet extends StatefulWidget {
  /// Callback when WhatsApp is successfully saved
  final VoidCallback? onSuccess;

  const WhatsAppRequiredSheet({
    super.key,
    this.onSuccess,
  });

  /// Show the WhatsApp required bottom sheet
  static Future<bool> show(BuildContext context, {VoidCallback? onSuccess}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhatsAppRequiredSheet(onSuccess: onSuccess),
    );
    return result ?? false;
  }

  @override
  State<WhatsAppRequiredSheet> createState() => _WhatsAppRequiredSheetState();
}

class _WhatsAppRequiredSheetState extends State<WhatsAppRequiredSheet> {
  final _phoneController = TextEditingController();
  List<Country> _countries = [];
  Country? _selectedCountry;
  bool _isLoading = false;
  bool _isLoadingCountries = true;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final repository = getIt<MobileMoneyRepository>();
      final result = await repository.getCountries();
      result.fold(
        (error) {
          setState(() {
            _isLoadingCountries = false;
            _countries = [];
          });
        },
        (countries) {
          setState(() {
            _isLoadingCountries = false;
            _countries = countries;
            _selectedCountry = countries.firstWhere(
              (c) => c.codeAlpha2 == 'RW',
              orElse: () => countries.first,
            );
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
        _countries = [];
      });
    }
  }

  bool get _isValidPhone {
    final phone = _phoneController.text.trim();
    return phone.length >= 8 && RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  void _saveWhatsApp() {
    if (!_isValidPhone) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final fullPhone = '${_selectedCountry?.phonePrefix ?? "+250"}${_phoneController.text.trim()}';

    context.read<ProfileBloc>().add(
          UpdateProfileRequested(whatsappNumber: fullPhone),
        );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdated) {
          setState(() => _isLoading = false);
          widget.onSuccess?.call();
          Navigator.of(context).pop(true);
        } else if (state is ProfileError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.message_rounded,
                        size: 32,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Center(
                    child: Text(
                      'Add Your WhatsApp',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Center(
                    child: Text(
                      'Required to connect with riders and drivers',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Country selector
                  if (_isLoadingCountries)
                    const Center(child: CircularProgressIndicator())
                  else if (_countries.isNotEmpty && _selectedCountry != null)
                    _CountryDropdown(
                      countries: _countries,
                      selectedCountry: _selectedCountry!,
                      onChanged: (country) =>
                          setState(() => _selectedCountry = country),
                    ),

                  const SizedBox(height: 12),

                  // Phone input
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Dial code
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            _selectedCountry?.phonePrefix ?? '+250',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Phone field
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_isValidPhone && !_isLoading)
                          ? _saveWhatsApp
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Country dropdown selector
class _CountryDropdown extends StatelessWidget {
  final List<Country> countries;
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;

  const _CountryDropdown({
    required this.countries,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Country>(
          value: selectedCountry,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          items: countries.map((country) {
            return DropdownMenuItem(
              value: country,
              child: Row(
                children: [
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    country.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (country) {
            if (country != null) {
              HapticFeedback.selectionClick();
              onChanged(country);
            }
          },
        ),
      ),
    );
  }
}
