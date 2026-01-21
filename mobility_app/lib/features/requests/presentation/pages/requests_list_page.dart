import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/config/route_config.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../domain/entities/ride_request.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';
import '../bloc/request_state.dart';

/// Main requests list page showing incoming and outgoing requests
///
/// Features:
/// - Two tabs: Incoming | Outgoing
/// - Pull-to-refresh
/// - Request status badges
/// - Countdown indication for pending requests
/// - Empty states and error handling
class RequestsListPage extends StatefulWidget {
  const RequestsListPage({super.key});

  @override
  State<RequestsListPage> createState() => _RequestsListPageState();
}

class _RequestsListPageState extends State<RequestsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
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
      _loadRequests();
    }
  }

  void _loadRequests() {
    final bloc = context.read<RequestBloc>();
    if (_tabController.index == 0) {
      bloc.add(const LoadIncomingRequests());
    } else {
      bloc.add(const LoadOutgoingRequests());
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    _loadRequests();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToRequest(RideRequest request, bool isIncoming) {
    HapticFeedback.lightImpact();
    
    if (request.isPending) {
      if (isIncoming) {
        Navigator.pushNamed(
          context,
          RouteConfig.incomingRequest,
          arguments: request,
        );
      } else {
        Navigator.pushNamed(
          context,
          RouteConfig.requestWaiting,
          arguments: request,
        );
      }
    } else if (request.isAccepted) {
      Navigator.pushNamed(
        context,
        RouteConfig.requestAccepted,
        arguments: {'request': request, 'isSender': !isIncoming},
      );
    }
    // For denied/expired/cancelled - just show details (could add a details page later)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            _buildTabs(theme),
            const SizedBox(height: 16),

            // Request list
            Expanded(
              child: BlocBuilder<RequestBloc, RequestState>(
                builder: (context, state) {
                  if (state is RequestLoading) {
                    return _buildShimmerLoading();
                  }

                  if (state is RequestError) {
                    return _buildErrorView(state.message, theme);
                  }

                  final requests = _tabController.index == 0
                      ? state.incomingRequests
                      : state.outgoingRequests;

                  if (requests.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return _buildRequestList(
                    requests,
                    theme,
                    isIncoming: _tabController.index == 0,
                  );
                },
              ),
            ),
          ],
        ),
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
                  Icon(Icons.call_received, size: 20),
                  SizedBox(width: 8),
                  Text('Incoming'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.call_made, size: 20),
                  SizedBox(width: 8),
                  Text('Outgoing'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(
    List<RideRequest> requests,
    ThemeData theme, {
    required bool isIncoming,
  }) {
    // Sort requests: pending first, then by createdAt descending
    final sortedRequests = List<RideRequest>.from(requests)
      ..sort((a, b) {
        if (a.isPending && !b.isPending) return -1;
        if (!a.isPending && b.isPending) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: sortedRequests.length,
        itemBuilder: (context, index) {
          final request = sortedRequests[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RequestCard(
              request: request,
              isIncoming: isIncoming,
              onTap: () => _navigateToRequest(request, isIncoming),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final type = _tabController.index == 0 ? 'incoming' : 'outgoing';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0
                  ? Icons.inbox_outlined
                  : Icons.outbox_outlined,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'No $type requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tabController.index == 0
                  ? 'Requests from other users will appear here'
                  : 'Requests you send will appear here',
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
              onPressed: _loadRequests,
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
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 100,
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

/// Individual request card widget
class _RequestCard extends StatelessWidget {
  final RideRequest request;
  final bool isIncoming;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.isIncoming,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = isIncoming ? request.fromUser : request.toUser;
    final timeAgo = _formatTimeAgo(request.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              imageUrl: user?.avatarUrl,
              initials: user?.initials ?? '?',
              size: 56,
              isOnline: request.isPending,
            ),
            const SizedBox(width: 16),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user?.name ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(theme),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user != null) ...[
                    Row(
                      children: [
                        RatingStars(
                          rating: user.rating,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (user.vehicleCategory != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            _getVehicleIcon(user.vehicleCategory!),
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (request.isPending) ...[
                        const Spacer(),
                        _buildCountdownChip(theme),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color color;
    String text;
    IconData icon;

    if (request.isPending) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.hourglass_top;
    } else if (request.isAccepted) {
      color = Colors.green;
      text = 'Accepted';
      icon = Icons.check_circle;
    } else if (request.isDenied) {
      color = Colors.red;
      text = 'Denied';
      icon = Icons.cancel;
    } else if (request.isExpired) {
      color = Colors.grey;
      text = 'Expired';
      icon = Icons.timer_off;
    } else {
      color = Colors.grey;
      text = 'Cancelled';
      icon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownChip(ThemeData theme) {
    final seconds = request.secondsRemaining;
    final isUrgent = seconds <= 15;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUrgent ? Colors.red : theme.colorScheme.primary)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 14,
            color: isUrgent ? Colors.red : theme.colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${seconds}s',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUrgent ? Colors.red : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String category) {
    switch (category.toLowerCase()) {
      case 'moto':
        return Icons.two_wheeler;
      case 'cab':
        return Icons.local_taxi;
      case 'truck':
        return Icons.local_shipping;
      case 'liffan':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
