import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/station_marker.dart';
import '../bloc/station_locator_bloc.dart';
import '../bloc/station_locator_event.dart';
import '../bloc/station_locator_state.dart';
import 'station_list_card.dart';
import 'station_list_shimmer.dart';
import 'sort_bottom_sheet.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

/// Enhanced list view for displaying stations with search, filter, sort, and pagination
class StationListView extends StatefulWidget {
  final String stationType;

  const StationListView({
    super.key,
    required this.stationType,
  });

  @override
  State<StationListView> createState() => _StationListViewState();
}

class _StationListViewState extends State<StationListView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  
  String _sortBy = 'distance';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    
    // Pagination listener
    _scrollController.addListener(_onScroll);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStations();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadStations() {
    context.read<StationLocatorBloc>().add(
      LoadNearbyStations(stationType: widget.stationType),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.85) {
      // Load more when scrolled 85% down
      context.read<StationLocatorBloc>().add(const LoadMoreStations());
    }
  }

  void _handleSearch(String query) {
    // Cancel previous timer
    _searchDebounce?.cancel();
    
    // Create new timer with 500ms debounce
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<StationLocatorBloc>().add(SearchStations(query: query));
    });
    
    // Update UI for clear button
    setState(() {});
  }

  void _showSortOptions() {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SortBottomSheet(
        currentSort: _sortBy,
        onSortSelected: (sortBy) {
          setState(() => _sortBy = sortBy);
          context.read<StationLocatorBloc>().add(UpdateSortBy(sortBy: sortBy));
          Navigator.pop(context);
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    context.read<StationLocatorBloc>().add(const RefreshStations());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search and filter bar
        _buildSearchBar(theme),

        // Filter chips
        _buildFiltersBar(theme),

        // Station list
        Expanded(
          child: BlocBuilder<StationLocatorBloc, StationLocatorState>(
            builder: (context, state) {
              if (state is StationLocatorLoading) {
                if (state.previousStations != null && state.previousStations!.isNotEmpty) {
                  // Show previous stations while refreshing
                  return _buildStationList(
                    stations: state.previousStations!,
                    favoriteIds: const {},
                    hasMore: false,
                    isLoadingMore: false,
                    theme: theme,
                  );
                }
                return const StationListShimmerList();
              }

              if (state is StationLocatorError) {
                if (state.previousStations != null && state.previousStations!.isNotEmpty) {
                  // Show previous stations on error
                  return _buildStationList(
                    stations: state.previousStations!,
                    favoriteIds: const {},
                    hasMore: false,
                    isLoadingMore: false,
                    theme: theme,
                  );
                }
                return _buildErrorView(state.message, theme);
              }

              if (state is StationLocatorLoaded) {
                if (state.stations.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return _buildStationList(
                  stations: state.stations,
                  favoriteIds: state.favoriteIds,
                  hasMore: state.hasMore,
                  isLoadingMore: state.isLoadingMore,
                  theme: theme,
                );
              }

              return const StationListShimmerList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GlassmorphicCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                decoration: InputDecoration(
                  hintText: 'Search stations...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Sort button
          GlassmorphicCard(
            padding: const EdgeInsets.all(12),
            onTap: _showSortOptions,
            child: const Icon(Icons.sort),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar(ThemeData theme) {
    return BlocBuilder<StationLocatorBloc, StationLocatorState>(
      builder: (context, state) {
        final filters = state is StationLocatorLoaded ? state.filters : <String, bool>{};
        final isOperatingFilter = filters['operating_now'] ?? false;
        final isAvailabilityFilter = filters['high_availability'] ?? false;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Favorites filter
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text('Favorites'),
                  ],
                ),
                selected: _showFavoritesOnly,
                onSelected: (selected) {
                  setState(() => _showFavoritesOnly = selected);
                  HapticFeedback.selectionClick();
                  context.read<StationLocatorBloc>().add(
                    ToggleFilter(key: 'favorites', value: selected),
                  );
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: _showFavoritesOnly
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Operating now filter
              FilterChip(
                label: const Text('Open Now'),
                selected: isOperatingFilter,
                onSelected: (selected) {
                  HapticFeedback.selectionClick();
                  context.read<StationLocatorBloc>().add(
                    ToggleFilter(key: 'operating_now', value: selected),
                  );
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: Colors.green.withValues(alpha: 0.2),
                checkmarkColor: Colors.green,
              ),
              
              const SizedBox(width: 8),
              
              // High availability filter
              FilterChip(
                label: const Text('Available'),
                selected: isAvailabilityFilter,
                onSelected: (selected) {
                  HapticFeedback.selectionClick();
                  context.read<StationLocatorBloc>().add(
                    ToggleFilter(key: 'high_availability', value: selected),
                  );
                },
                backgroundColor: theme.colorScheme.surface,
                selectedColor: Colors.orange.withValues(alpha: 0.2),
                checkmarkColor: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStationList({
    required List<StationMarker> stations,
    required Set<String> favoriteIds,
    required bool hasMore,
    required bool isLoadingMore,
    required ThemeData theme,
  }) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: stations.length + (hasMore || isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator for pagination
          if (index == stations.length) {
            return _buildLoadMoreIndicator(theme);
          }

          final station = stations[index];
          final isFavorite = favoriteIds.contains(station.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StationListCard(
              station: station,
              stationType: widget.stationType,
              isFavorite: isFavorite,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.read<StationLocatorBloc>().add(
                  SelectStation(stationId: station.id),
                );
                // Navigate to details page
                context.push(
                  '/station-details/${widget.stationType}/${station.id}',
                  extra: station,
                );
              },
              onFavoriteTap: () {
                context.read<StationLocatorBloc>().add(
                  ToggleFavorite(
                    stationType: widget.stationType,
                    stationId: station.id,
                  ),
                );
              },
              onNavigateTap: () {
                _navigateToStation(station);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading more stations...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isBatterySwap = widget.stationType == 'battery_swap';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBatterySwap ? Icons.battery_unknown : Icons.ev_station,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No stations found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'No ${isBatterySwap ? 'battery swap' : 'charging'} stations nearby',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _showFavoritesOnly = false;
                });
                context.read<StationLocatorBloc>().add(const ClearFilters());
                _loadStations();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStations,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToStation(StationMarker station) async {
    HapticFeedback.mediumImpact();
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.position.latitude},${station.position.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }
}
