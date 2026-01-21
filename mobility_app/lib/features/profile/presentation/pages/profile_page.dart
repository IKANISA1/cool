import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/vehicle_icon.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../ratings/presentation/bloc/ratings_bloc.dart';
import '../../../ratings/presentation/bloc/ratings_event.dart';
import '../../../ratings/presentation/widgets/ratings_section.dart';

/// Profile view page displaying user info, stats, and settings access
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const LoadProfileRequested()),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                return _ProfileContent(profile: state.profile);
              }
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const Center(child: Text('No profile data'));
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Profile profile;

  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header with avatar
        SliverToBoxAdapter(
          child: _buildHeader(context, theme, size),
        ),

        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildStatsRow(theme),
          ),
        ),

        // Vehicle section (for drivers)
        if (profile.canDrive) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: _buildSectionTitle(theme, 'Your Vehicle'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildVehicleCard(theme),
            ),
          ),
        ],

        // Reviews section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildSectionTitle(theme, 'Reviews'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BlocProvider(
              create: (_) => getIt<RatingsBloc>()..add(LoadRatingsRequested(profile.id)),
              child: RatingsSection(userId: profile.id),
            ),
          ),
        ),

        // Menu items
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildSectionTitle(theme, 'Settings'),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildMenuItems(context, theme),
          ),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, Size size) {
    return Stack(
      children: [
        // Glassmorphic background
        Container(
          height: 280,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.2),
                theme.colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.pushNamed(context, '/profile/edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar with badges
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: UserAvatar(
                        initials: profile.name.isNotEmpty 
                            ? profile.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
                            : '?',
                        imageUrl: profile.avatarUrl,
                        size: 100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  profile.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '4.8',
            label: 'Rating',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '156',
            label: 'Trips',
            icon: Icons.navigation_rounded,
            iconColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '2y',
            label: 'Member',
            icon: Icons.calendar_today_rounded,
            iconColor: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(ThemeData theme) {
    return GlassmorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: VehicleIcon(
                category: profile.vehicleCategory?.name ?? 'other',
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.vehicleCategory?.displayName ?? 'No vehicle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to manage your vehicle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
      onTap: () {
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildMenuItems(BuildContext context, ThemeData theme) {
    final menuItems = [
      _MenuItem(
        icon: Icons.person_outline_rounded,
        title: 'Edit Profile',
        route: '/profile/edit',
      ),
      _MenuItem(
        icon: Icons.directions_car_outlined,
        title: 'Vehicles',
        route: '/settings/vehicles',
      ),
      _MenuItem(
        icon: Icons.contact_phone_outlined,
        title: 'Contact Settings',
        route: '/settings',
      ),
      _MenuItem(
        icon: Icons.payment_outlined,
        title: 'Payment Methods',
        route: '/settings/payments',
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        title: 'Trip History',
        route: '/trips/history',
      ),
      _MenuItem(
        icon: Icons.security_outlined,
        title: 'Safety',
        route: '/settings/safety',
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        title: 'Help & Support',
        route: '/support',
      ),
      _MenuItem(
        icon: Icons.logout_rounded,
        title: 'Sign Out',
        isDestructive: true,
        route: '/auth/signout',
      ),
    ];

    return GlassmorphicCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (item.route != null) {
                    Navigator.pushNamed(context, item.route!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: item.isDestructive
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: item.isDestructive
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                      if (!item.isDestructive)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? route;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.route,
    this.isDestructive = false,
  });
}
