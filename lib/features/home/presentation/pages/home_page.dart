import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/config/route_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/presence_service.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../discovery/presentation/pages/discovery_page.dart';
import '../../../discovery/presentation/bloc/discovery_bloc.dart';
import '../../../ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// Main home page with glassmorphic bottom navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildHomeTab(BuildContext context) {
    return const _HomeContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // For glassmorphic nav bar
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(context),
          BlocProvider(
            create: (_) {
              final DiscoveryBloc bloc = GetIt.instance<DiscoveryBloc>();
              return bloc;
            },
            child: const DiscoveryPage(),
          ),
          BlocProvider(
            create: (_) {
              final AIAssistantBloc bloc = GetIt.instance<AIAssistantBloc>();
              return bloc;
            },
            child: const AIAssistantPage(),
          ),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: GlassTheme.glassDecoration(
          context: context,
          blur: 20,
          borderRadius: 20,
        ).copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: NavigationBar(
            elevation: 0,
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            selectedIndex: _currentIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'AI',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home content with quick actions and glassmorphic design
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/map_bg_blur.png'), // Placeholder background
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.surface.withValues(alpha: 0.8),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'John Doe', // TODO: Get from Bloc
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Notifications bell icon
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pushNamed(context, RouteConfig.notifications);
                            },
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                          // Unread badge
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const UserAvatar(
                        imageUrl: null,
                        initials: '?',
                        size: 48,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Online Status Bar - Interactive toggle
              const _OnlineStatusBar(),
              const SizedBox(height: 24),

              // Main CTA
              Text(
                'Where to?',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Glassmorphic Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.explore,
                      label: 'Find Drivers',
                      color: Colors.blue,
                      onTap: () {
                        // Switch to Discover tab (index 1)
                        context.findAncestorStateOfType<_HomePageState>()?.setTab(1);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.auto_awesome,
                      label: 'AI Assistant',
                      color: Colors.purple,
                      onTap: () {
                         // Switch to AI tab (index 2)
                        context.findAncestorStateOfType<_HomePageState>()?.setTab(2);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.schedule,
                      label: 'Schedule',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pushNamed(context, RouteConfig.schedule);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.request_quote,
                      label: 'Requests',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(context, RouteConfig.requests);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Station Locator Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.battery_charging_full,
                      label: 'Battery Swap',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pushNamed(context, RouteConfig.batterySwapStations);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GlassActionCard(
                      icon: Icons.ev_station,
                      label: 'EV Charging',
                      color: Colors.cyan,
                      onTap: () {
                        Navigator.pushNamed(context, RouteConfig.evChargingStations);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Activity
              Text(
                'Recent Activity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const GlassmorphicCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                       Icon(Icons.history, color: Colors.grey),
                       SizedBox(width: 16),
                       Text('No recent trips'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GlassActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive online/offline status toggle bar
/// 
/// Uses PresenceService to manage online presence and location tracking.
class _OnlineStatusBar extends StatefulWidget {
  const _OnlineStatusBar();

  @override
  State<_OnlineStatusBar> createState() => _OnlineStatusBarState();
}

class _OnlineStatusBarState extends State<_OnlineStatusBar> {
  late final PresenceService _presenceService;
  bool _isOnline = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _presenceService = getIt<PresenceService>();
    _isOnline = _presenceService.isTracking;
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (_isOnline) {
        await _presenceService.goOffline();
      } else {
        await _presenceService.goOnline();
      }
      setState(() => _isOnline = !_isOnline);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isOnline
                ? [theme.colorScheme.primary, theme.colorScheme.secondary]
                : [Colors.grey.shade600, Colors.grey.shade700],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Status indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOnline ? Colors.greenAccent : Colors.grey.shade400,
                shape: BoxShape.circle,
                boxShadow: _isOnline
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isOnline ? 'You are Online' : 'You are Offline',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Toggle button
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isOnline ? 'Go Offline' : 'Go Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
