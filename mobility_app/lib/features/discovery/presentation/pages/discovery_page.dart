import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/route_config.dart';
import '../bloc/discovery_bloc.dart';
import '../bloc/discovery_event.dart';
import '../bloc/discovery_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/nearby_user_card.dart';
import '../widgets/online_toggle.dart';
import '../widgets/search_bar.dart';

/// Main discovery page for finding nearby drivers and passengers
///
/// Features:
/// - Two-tab view: Drivers | Passengers
/// - Realtime list updates via Supabase
/// - Smart search functionality
/// - Distance-based sorting
/// - Vehicle type filtering (for drivers)
/// - Online/offline toggle
/// - Pull-to-refresh
/// - Infinite scroll/pagination
/// - Shimmer loading states
class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<String> _selectedVehicleFilters = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes
    _tabController.addListener(_onTabChanged);

    // Set up scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Auto-enable online status and load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<DiscoveryBloc>();
      bloc.add(const ToggleOnlineStatusEvent(true));
      bloc.add(const SubscribeToUpdates());
      _loadNearbyUsers();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    context.read<DiscoveryBloc>().add(const UnsubscribeFromUpdates());
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Clear filters when switching tabs
      setState(() {
        _selectedVehicleFilters = [];
      });
      _loadNearbyUsers();
    }
  }

  void _loadNearbyUsers() {
    final role = _tabController.index == 0 ? 'driver' : 'passenger';
    context.read<DiscoveryBloc>().add(
          LoadNearbyUsers(
            role: role,
            searchQuery: _searchController.text.isNotEmpty
                ? _searchController.text
                : null,
            vehicleFilters:
                _selectedVehicleFilters.isNotEmpty ? _selectedVehicleFilters : null,
          ),
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<DiscoveryBloc>().add(const LoadMoreUsers());
    }
  }

  void _handleSearch(String query) {
    context.read<DiscoveryBloc>().add(SearchUsersEvent(query));
  }

  void _toggleVehicleFilter(String vehicle) {
    setState(() {
      if (vehicle == 'all') {
        _selectedVehicleFilters.clear();
      } else {
        if (_selectedVehicleFilters.contains(vehicle)) {
          _selectedVehicleFilters.remove(vehicle);
        } else {
          _selectedVehicleFilters.add(vehicle);
        }
      }
    });
    context.read<DiscoveryBloc>().add(ApplyFiltersEvent(_selectedVehicleFilters));
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    context.read<DiscoveryBloc>().add(const RefreshNearbyUsers());
    // Wait a bit for the refresh to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.03),
              theme.colorScheme.secondary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(theme),

              // Tabs
              _buildTabs(theme),

              const SizedBox(height: 16),

              // Search and filters
              _buildSearchAndFilters(theme),

              const SizedBox(height: 8),

              // User list
              Expanded(
                child: BlocBuilder<DiscoveryBloc, DiscoveryState>(
                  builder: (context, state) {
                    if (state is DiscoveryLoading && state.users.isEmpty) {
                      return _buildShimmerLoading();
                    }

                    if (state is DiscoveryError && state.users.isEmpty) {
                      return _buildErrorView(state.message, theme);
                    }

                    if (state is DiscoveryLoaded && state.users.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return _buildUserList(state, theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              BlocBuilder<DiscoveryBloc, DiscoveryState>(
                builder: (context, state) {
                  final count = state.users.length;
                  final type = _tabController.index == 0 ? 'drivers' : 'passengers';
                  return Text(
                    '$count $type found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ],
          ),

          // Online toggle
          BlocBuilder<DiscoveryBloc, DiscoveryState>(
            buildWhen: (previous, current) => previous.isOnline != current.isOnline,
            builder: (context, state) {
              return OnlineToggle(
                isOnline: state.isOnline,
                onToggle: (value) {
                  HapticFeedback.mediumImpact();
                  context.read<DiscoveryBloc>().add(ToggleOnlineStatusEvent(value));
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drive_eta, size: 20),
                  SizedBox(width: 8),
                  Text('Drivers'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Passengers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Search bar
          CustomSearchBar(
            controller: _searchController,
            onChanged: _handleSearch,
            hintText: 'Search by name...',
            onVoiceSearch: () {
              // TODO: Implement voice search
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice search coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          // Vehicle filters (only for drivers tab)
          if (_tabController.index == 0) ...[
            const SizedBox(height: 12),
            FilterChips(
              selectedTypes: _selectedVehicleFilters,
              onToggle: _toggleVehicleFilter,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList(DiscoveryState state, ThemeData theme) {
    final isLoadingMore =
        state is DiscoveryLoading && (state).isLoadingMore;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: state.users.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.users.length) {
            // Loading indicator for pagination
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLoadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const SizedBox.shrink(),
              ),
            );
          }

          final user = state.users[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NearbyUserCard(
              user: user,
              onRequestTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pushNamed(
                  context,
                  RouteConfig.sendRequest,
                  arguments: user,
                );
              },
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/user-profile',
                  arguments: user,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final type = _tabController.index == 0 ? 'drivers' : 'passengers';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No $type nearby',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding your search or check back later',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
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
              onPressed: _loadNearbyUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: NearbyUserCardShimmer(),
          );
        },
      ),
    );
  }
}
