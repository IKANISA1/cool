import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Country data for supported regions
/// Only Rwanda, Burundi, DR Congo, Tanzania are supported
/// NO Uganda, Kenya, Nigeria
class Country {
  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final List<String> languages;

  const Country({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.languages,
  });
}

/// Available countries - ONLY supported regions
/// NO Luganda, Kirundi, Uganda, Kenya, Nigeria
const List<Country> availableCountries = [
  Country(
    code: 'RWA',
    name: 'Rwanda',
    flag: '🇷🇼',
    dialCode: '+250',
    languages: ['Kinyarwanda', 'English', 'French'],
  ),
  Country(
    code: 'BDI',
    name: 'Burundi',
    flag: '🇧🇮',
    dialCode: '+257',
    languages: ['French', 'English'],
  ),
  Country(
    code: 'COD',
    name: 'DR Congo',
    flag: '🇨🇩',
    dialCode: '+243',
    languages: ['French', 'Swahili'],
  ),
  Country(
    code: 'TZA',
    name: 'Tanzania',
    flag: '🇹🇿',
    dialCode: '+255',
    languages: ['Swahili', 'English'],
  ),
];

/// Country selector with search functionality
class CountrySelector extends StatefulWidget {
  final String selectedCountry;
  final ValueChanged<String> onCountrySelected;

  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  final _searchController = TextEditingController();
  List<Country> _filteredCountries = availableCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = availableCountries;
      } else {
        _filteredCountries = availableCountries.where((country) {
          return country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search field
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Country list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredCountries.length,
            itemBuilder: (context, index) {
              final country = _filteredCountries[index];
              final isSelected = widget.selectedCountry == country.code;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CountryTile(
                  country: country,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCountrySelected(country.code);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryTile({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surface.withValues(alpha: 0.6),
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
                  // Flag
                  Text(
                    country.flag,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),

                  // Country info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${country.code} • ${country.dialCode}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selected indicator
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
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
