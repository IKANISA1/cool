import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/injection.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/auth_wrapper.dart';
import '../../features/discovery/presentation/bloc/discovery_bloc.dart';
import '../../features/discovery/presentation/pages/discovery_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/profile_event.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/requests/presentation/bloc/request_bloc.dart';
import '../../features/requests/presentation/bloc/request_event.dart';
import '../../features/requests/presentation/pages/send_request_page.dart';
import '../../features/requests/presentation/pages/request_waiting_page.dart';
import '../../features/requests/presentation/pages/incoming_request_page.dart';
import '../../features/requests/presentation/pages/request_accepted_page.dart';
import '../../features/requests/presentation/pages/requests_list_page.dart';
import '../../features/requests/domain/entities/ride_request.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';
import '../../features/scheduling/presentation/bloc/scheduling_bloc.dart';
import '../../features/scheduling/presentation/pages/scheduling_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/trips/presentation/pages/trip_history_page.dart';
import '../../features/station_locator/presentation/bloc/station_locator_bloc.dart';
import '../../features/station_locator/presentation/bloc/station_locator_event.dart';
import '../../features/station_locator/presentation/pages/station_locator_page.dart';

/// Route configuration for the app
///
/// Defines all named routes and their corresponding pages.
class RouteConfig {
  RouteConfig._();

  // ═══════════════════════════════════════════════════════════
  // ROUTE NAMES
  // ═══════════════════════════════════════════════════════════

  // Auth routes
  static const String splash = '/';
  static const String phoneAuth = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String onboarding = '/onboarding';
  static const String profileSetup = '/profile/setup';

  // Main routes
  static const String home = '/home';
  static const String discovery = '/discovery';
  static const String map = '/discovery/map';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Request routes
  static const String requests = '/requests';
  static const String requestDetails = '/requests/:id';

  // Scheduling routes
  static const String schedule = '/schedule';
  static const String aiSchedule = '/schedule/ai';
  static const String scheduleDetails = '/schedule/:id';

  // AI Assistant routes
  static const String aiAssistant = '/ai';

  // Request flow routes
  static const String sendRequest = '/request/send';
  static const String requestWaiting = '/request-waiting';
  static const String incomingRequest = '/request/incoming';
  static const String requestAccepted = '/request-accepted';

  // AI Trip confirmation
  static const String aiTripConfirm = '/ai/confirm';

  // Settings routes
  static const String settings = '/settings';
  static const String vehicles = '/settings/vehicles';

  // Notifications
  static const String notifications = '/notifications';

  // Trips
  static const String tripHistory = '/trips/history';

  // Station Locator routes
  static const String batterySwapStations = '/stations/battery-swap';
  static const String evChargingStations = '/stations/ev-charging';

  // ═══════════════════════════════════════════════════════════
  // ROUTE GENERATION
  // ═══════════════════════════════════════════════════════════

  /// Generate the app's route map
  /// 
  /// Auth routes use the actual Auth pages with BlocProvider,
  /// other routes are placeholders until implemented.
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: const AuthWrapper(),
    ),
    onboarding: (context) => const _PlaceholderPage(title: 'Onboarding'),
    profileSetup: (context) => BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: const ProfileSetupPage(),
    ),
    home: (context) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ProfileBloc>()..add(const LoadProfileRequested())),
        BlocProvider(create: (_) => getIt<RequestBloc>()..add(const LoadIncomingRequests())),
      ],
      child: const HomePage(),
    ),
    discovery: (context) => BlocProvider(
      create: (_) => getIt<DiscoveryBloc>(),
      child: const DiscoveryPage(),
    ),
    profile: (context) => BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const LoadProfileRequested()),
      child: const ProfilePage(),
    ),
    editProfile: (context) => BlocProvider(
      create: (_) => getIt<ProfileBloc>(),
      child: const ProfileSetupPage(), // Reuse setup page for editing
    ),
    requests: (context) => BlocProvider(
      create: (_) => getIt<RequestBloc>()
        ..add(const LoadIncomingRequests())
        ..add(const SubscribeToIncomingRequests()),
      child: const RequestsListPage(),
    ),
    schedule: (context) => BlocProvider(
      create: (_) => getIt<SchedulingBloc>(),
      child: const SchedulingPage(),
    ),
    aiAssistant: (context) => BlocProvider(
      create: (_) => getIt<AIAssistantBloc>(),
      child: const AIAssistantPage(),
    ),
    settings: (context) => BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const SettingsPage(),
    ),
    notifications: (context) => BlocProvider(
      create: (_) => NotificationsBloc(),
      child: const NotificationsPage(),
    ),
    tripHistory: (context) => const TripHistoryPage(),
    batterySwapStations: (context) => BlocProvider(
      create: (_) => getIt<StationLocatorBloc>()
        ..add(const LoadNearbyStations(stationType: 'battery_swap')),
      child: const StationLocatorPage(stationType: 'battery_swap'),
    ),
    evChargingStations: (context) => BlocProvider(
      create: (_) => getIt<StationLocatorBloc>()
        ..add(const LoadNearbyStations(stationType: 'ev_charging')),
      child: const StationLocatorPage(stationType: 'ev_charging'),
    ),
  };

  /// Handle dynamic routes with parameters
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle routes with parameters like /requests/:id
    final uri = Uri.parse(settings.name ?? '');
    final pathSegments = uri.pathSegments;

    // Request details: /requests/:id
    if (pathSegments.length == 2 && pathSegments[0] == 'requests') {
      final requestId = pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => _PlaceholderPage(
          title: 'Request Details',
          subtitle: 'ID: $requestId',
        ),
        settings: settings,
      );
    }

    // Schedule details: /schedule/:id
    if (pathSegments.length == 2 && pathSegments[0] == 'schedule') {
      final scheduleId = pathSegments[1];
      return MaterialPageRoute(
        builder: (context) => _PlaceholderPage(
          title: 'Schedule Details',
          subtitle: 'ID: $scheduleId',
        ),
        settings: settings,
      );
    }

    // Unknown route
    return MaterialPageRoute(
      builder: (context) => const _PlaceholderPage(title: '404 Not Found'),
      settings: settings,
    );
  }

  /// Handle routes with arguments
  static Route<dynamic> onGenerateRouteWithArgs(RouteSettings settings) {
    switch (settings.name) {
      case sendRequest:
        // Expects a recipient user as argument
        return _buildPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => getIt<RequestBloc>(),
            child: SendRequestPage(recipient: settings.arguments),
          ),
        );

      case requestWaiting:
        final request = settings.arguments as RideRequest;
        return _buildPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => getIt<RequestBloc>(),
            child: RequestWaitingPage(request: request),
          ),
        );

      case incomingRequest:
        final request = settings.arguments as RideRequest;
        return _buildPageRoute(
          settings: settings,
          builder: (context) => BlocProvider(
            create: (_) => getIt<RequestBloc>(),
            child: IncomingRequestPage(request: request),
          ),
        );

      case requestAccepted:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildPageRoute(
          settings: settings,
          builder: (context) => RequestAcceptedPage(
            request: args['request'] as RideRequest,
            isSender: args['isSender'] as bool? ?? true,
          ),
        );

      default:
        return onGenerateRoute(settings) ?? MaterialPageRoute(
          builder: (context) => const _PlaceholderPage(title: '404 Not Found'),
        );
    }
  }

  /// Helper to build page routes with slide transition
  static PageRoute<T> _buildPageRoute<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Placeholder page for routes not yet implemented
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _PlaceholderPage({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
