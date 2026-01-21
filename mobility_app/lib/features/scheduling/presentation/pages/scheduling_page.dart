import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../domain/entities/scheduled_trip.dart';
import '../bloc/scheduling_bloc.dart';
import '../bloc/scheduling_event.dart';
import '../bloc/scheduling_state.dart';
import '../widgets/trip_card.dart';
import 'create_trip_page.dart';

/// Main scheduling page showing scheduled trips
///
/// Features:
/// - Two tabs: Offers | Requests
/// - Pull-to-refresh
/// - AI voice input for natural language scheduling
/// - Quick filters (today, this week, etc.)
class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTrips();
    }
  }

  void _loadTrips() {
    final tripType = _tabController.index == 0 ? TripType.offer : TripType.request;
    context.read<SchedulingBloc>().add(LoadUpcomingTrips(tripType: tripType));
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    _loadTrips();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _openCreateTrip() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SchedulingBloc>(),
          child: CreateTripPage(
            initialTripType: _tabController.index == 0 ? TripType.offer : TripType.request,
          ),
        ),
      ),
    );
  }

  void _openAiScheduler() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/schedule/ai');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            // Tabs
            _buildTabs(theme),

            const SizedBox(height: 16),

            // Trip list
            Expanded(
              child: BlocBuilder<SchedulingBloc, SchedulingState>(
                builder: (context, state) {
                  if (state is SchedulingLoading) {
                    return _buildShimmerLoading();
                  }

                  if (state is SchedulingError) {
                    return _buildErrorView(state.message, theme);
                  }

                  if (state is SchedulingLoaded && state.upcomingTrips.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  if (state is SchedulingLoaded) {
                    return _buildTripList(state.upcomingTrips, theme);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Voice input FAB
          FloatingActionButton.small(
            heroTag: 'ai_schedule',
            onPressed: _openAiScheduler,
            backgroundColor: theme.colorScheme.secondary,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          // Create trip FAB
          FloatingActionButton.extended(
            heroTag: 'create_trip',
            onPressed: _openCreateTrip,
            icon: const Icon(Icons.add),
            label: const Text('Schedule'),
          ),
        ],
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
                'Scheduled Trips',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Plan your rides in advance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
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
                  Icon(Icons.local_offer, size: 20),
                  SizedBox(width: 8),
                  Text('Offers'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.front_hand, size: 20),
                  SizedBox(width: 8),
                  Text('Requests'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<ScheduledTrip> trips, ThemeData theme) {
    // Group trips by date
    final groupedTrips = _groupTripsByDate(trips);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        itemCount: groupedTrips.length,
        itemBuilder: (context, index) {
          final entry = groupedTrips.entries.elementAt(index);
          final dateLabel = entry.key;
          final dateTrips = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  dateLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Trips for this date
              ...dateTrips.map((trip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TripCard(
                      trip: trip,
                      onTap: () => _viewTripDetails(trip),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<ScheduledTrip>> _groupTripsByDate(List<ScheduledTrip> trips) {
    final Map<String, List<ScheduledTrip>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final trip in trips) {
      final tripDate = DateTime(
        trip.whenDateTime.year,
        trip.whenDateTime.month,
        trip.whenDateTime.day,
      );

      String label;
      if (tripDate == today) {
        label = 'Today';
      } else if (tripDate == tomorrow) {
        label = 'Tomorrow';
      } else {
        label = DateFormat('EEEE, MMM d').format(trip.whenDateTime);
      }

      grouped.putIfAbsent(label, () => []).add(trip);
    }

    return grouped;
  }

  void _viewTripDetails(ScheduledTrip trip) {
    Navigator.pushNamed(
      context,
      '/schedule/${trip.id}',
      arguments: trip,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final type = _tabController.index == 0 ? 'offers' : 'requests';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No scheduled $type',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule your first trip using the button below',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
              onPressed: _loadTrips,
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}
