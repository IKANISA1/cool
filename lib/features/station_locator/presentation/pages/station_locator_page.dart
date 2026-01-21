import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/station_locator_bloc.dart';
import '../bloc/station_locator_event.dart';
import '../bloc/station_locator_state.dart';
import '../widgets/station_list_view.dart';
import 'station_map_view.dart';

/// Main page for station locator with list/map toggle
class StationLocatorPage extends StatefulWidget {
  /// Station type: 'battery_swap' or 'ev_charging'
  final String stationType;

  const StationLocatorPage({
    super.key,
    required this.stationType,
  });

  @override
  State<StationLocatorPage> createState() => _StationLocatorPageState();
}

class _StationLocatorPageState extends State<StationLocatorPage> {
  bool _isMapView = true;

  @override
  void initState() {
    super.initState();
    // Load stations when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StationLocatorBloc>().add(
            LoadNearbyStations(stationType: widget.stationType),
          );
    });
  }

  String get _title {
    return widget.stationType == 'battery_swap'
        ? 'Battery Swap Stations'
        : 'EV Charging Stations';
  }

  IconData get _stationIcon {
    return widget.stationType == 'battery_swap'
        ? Icons.battery_charging_full
        : Icons.ev_station;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_stationIcon, size: 24),
            const SizedBox(width: 8),
            Text(_title),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // View toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton(
                  icon: Icons.map_outlined,
                  isSelected: _isMapView,
                  onTap: () => _setMapView(true),
                  tooltip: 'Map View',
                ),
                _buildViewToggleButton(
                  icon: Icons.list,
                  isSelected: !_isMapView,
                  onTap: () => _setMapView(false),
                  tooltip: 'List View',
                ),
              ],
            ),
          ),

          // Filter button
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterSheet,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: BlocBuilder<StationLocatorBloc, StationLocatorState>(
        builder: (context, state) {
          if (state is StationLocatorLoading && state.previousStations == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding nearby stations...'),
                ],
              ),
            );
          }

          if (state is StationLocatorError && state.previousStations == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading stations',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show loading overlay if refreshing
          return Stack(
            children: [
              // Main view
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isMapView
                    ? StationMapView(
                        key: const ValueKey('map'),
                        stationType: widget.stationType,
                      )
                    : StationListView(
                        key: const ValueKey('list'),
                        stationType: widget.stationType,
                      ),
              ),

              // Loading overlay
              if (state is StationLocatorLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStation,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Station'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _setMapView(bool isMap) {
    if (_isMapView != isMap) {
      HapticFeedback.selectionClick();
      setState(() => _isMapView = isMap);
    }
  }

  void _showFilterSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(stationType: widget.stationType),
    );
  }

  void _addStation() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to add station page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add station feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _refresh() {
    context.read<StationLocatorBloc>().add(const RefreshStations());
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  final String stationType;

  const _FilterSheet({required this.stationType});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  double _radiusKm = 10;
  double? _minPowerKw;
  String? _connectorType;
  bool _availableOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEV = widget.stationType == 'ev_charging';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Filter Stations',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Radius slider
          Text('Search Radius', style: theme.textTheme.titleSmall),
          Slider(
            value: _radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radiusKm.toInt()} km',
            onChanged: (value) => setState(() => _radiusKm = value),
          ),
          const SizedBox(height: 16),

          // Available only toggle
          SwitchListTile(
            title: Text(isEV ? 'Available ports only' : 'Available batteries only'),
            value: _availableOnly,
            onChanged: (value) => setState(() => _availableOnly = value),
            contentPadding: EdgeInsets.zero,
          ),

          // EV-specific filters
          if (isEV) ...[
            const SizedBox(height: 16),
            Text('Minimum Power (kW)', style: theme.textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [null, 22.0, 50.0, 150.0].map((power) {
                final isSelected = _minPowerKw == power;
                return ChoiceChip(
                  label: Text(power == null ? 'Any' : '${power.toInt()}+ kW'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _minPowerKw = power),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Connector Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [null, 'CCS', 'CHAdeMO', 'Type2', 'Tesla'].map((type) {
                final isSelected = _connectorType == type;
                return ChoiceChip(
                  label: Text(type ?? 'Any'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _connectorType = type),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 32),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear All'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _applyFilters() {
    Navigator.pop(context);
    // TODO: Dispatch filter event to bloc
  }

  void _clearFilters() {
    setState(() {
      _radiusKm = 10;
      _minPowerKw = null;
      _connectorType = null;
      _availableOnly = false;
    });
  }
}
