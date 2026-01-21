import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/station_marker.dart';
import '../bloc/station_locator_bloc.dart';
import '../bloc/station_locator_event.dart';
import '../bloc/station_locator_state.dart';

/// List view for displaying stations in a scrollable list
class StationListView extends StatelessWidget {
  final String stationType;

  const StationListView({
    super.key,
    required this.stationType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationLocatorBloc, StationLocatorState>(
      builder: (context, state) {
        List<StationMarker> stations = [];
        
        if (state is StationLocatorLoaded) {
          stations = state.stations;
        } else if (state is StationLocatorLoading && state.previousStations != null) {
          stations = state.previousStations!;
        } else if (state is StationLocatorError && state.previousStations != null) {
          stations = state.previousStations!;
        }

        if (stations.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<StationLocatorBloc>().add(const RefreshStations());
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return _StationCard(
                station: station,
                onTap: () => _onStationTap(context, station),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isBatterySwap = stationType == 'battery_swap';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBatterySwap ? Icons.battery_alert : Icons.ev_station_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No stations found nearby',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBatterySwap
                  ? 'Try expanding your search radius or check back later for more battery swap locations.'
                  : 'Try expanding your search radius or adjusting filters to find EV charging stations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<StationLocatorBloc>().add(const RefreshStations());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  void _onStationTap(BuildContext context, StationMarker station) {
    HapticFeedback.selectionClick();
    context.read<StationLocatorBloc>().add(SelectStation(stationId: station.id));
    _showStationDetails(context, station);
  }

  void _showStationDetails(BuildContext context, StationMarker station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StationDetailsSheet(station: station),
    );
  }
}

/// Card widget for displaying a single station
class _StationCard extends StatelessWidget {
  final StationMarker station;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBatterySwap = station.isBatterySwap;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAvailabilityColor(colorScheme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isBatterySwap ? Icons.battery_charging_full : Icons.ev_station,
                  color: _getAvailabilityColor(colorScheme),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildRating(theme),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Brand/Network
                    if (station.brand != null || station.network != null)
                      Text(
                        station.brand ?? station.network ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Address
                    if (station.details['address'] != null)
                      Text(
                        station.details['address'].toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // Availability and info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildAvailabilityChip(theme, colorScheme),
                        if (isBatterySwap && station.details['operating_hours'] != null)
                          _buildInfoChip(
                            theme,
                            Icons.access_time,
                            station.details['operating_hours'].toString(),
                          ),
                        if (!isBatterySwap && station.details['max_power_kw'] != null)
                          _buildInfoChip(
                            theme,
                            Icons.bolt,
                            '${station.details['max_power_kw']} kW',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigate button
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating(ThemeData theme) {
    final rating = station.details['rating'] as double? ?? 0;
    if (rating == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 16, color: Colors.amber.shade600),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityChip(ThemeData theme, ColorScheme colorScheme) {
    final isBatterySwap = station.isBatterySwap;
    String text;

    if (isBatterySwap) {
      final available = station.details['batteries_available'] as int? ?? 0;
      final total = station.details['total_capacity'] as int? ?? 0;
      text = '$available / $total batteries';
    } else {
      final available = station.details['available_ports'] as int? ?? 0;
      final total = station.details['total_ports'] as int? ?? 0;
      text = '$available / $total ports';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getAvailabilityColor(colorScheme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: _getAvailabilityColor(colorScheme),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvailabilityColor(ColorScheme colorScheme) {
    if (!station.isOperational) return colorScheme.error;

    final isBatterySwap = station.isBatterySwap;
    final available = isBatterySwap
        ? station.details['batteries_available'] as int? ?? 0
        : station.details['available_ports'] as int? ?? 0;

    if (available == 0) return colorScheme.error;
    if (available <= 2) return Colors.orange;
    return Colors.green;
  }
}

/// Station details bottom sheet
class _StationDetailsSheet extends StatelessWidget {
  final StationMarker station;

  const _StationDetailsSheet({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
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

          // Name and rating
          Row(
            children: [
              Expanded(
                child: Text(
                  station.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if ((station.details['rating'] as double? ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        (station.details['rating'] as double).toStringAsFixed(1),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Brand/Network
          if (station.brand != null || station.network != null)
            Text(
              station.brand ?? station.network ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          const SizedBox(height: 4),

          // Address
          if (station.details['address'] != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined, 
                     size: 16, 
                     color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    station.details['address'].toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _navigateToStation(context),
                  icon: const Icon(Icons.directions),
                  label: const Text('Navigate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigate to full details page
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToStation(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.position.latitude},${station.position.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
