import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:ridelink/core/di/injection.dart';
import 'package:ridelink/features/splash/presentation/screens/splash_screen.dart';
import 'package:ridelink/features/schedule/presentation/pages/schedule_screen.dart';
import 'package:ridelink/features/profile/presentation/pages/profile_screen.dart';
import 'package:ridelink/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:ridelink/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:ridelink/features/profile/presentation/bloc/profile_event.dart';
import 'package:ridelink/features/scan/presentation/pages/qr_scanner_screen.dart';
import 'package:ridelink/features/payment/presentation/pages/nfc_payment_screen.dart';
import 'package:ridelink/features/auth/presentation/pages/auth_wrapper.dart';
import 'package:ridelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ridelink/features/home/presentation/pages/home_page.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_bloc.dart';
import 'package:ridelink/features/requests/presentation/bloc/request_event.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_bloc.dart';
import 'package:ridelink/features/station_locator/presentation/bloc/station_locator_event.dart';
import 'package:ridelink/features/station_locator/presentation/pages/station_locator_page.dart';
import 'package:ridelink/features/station_locator/presentation/pages/station_details_page.dart';
import 'package:ridelink/features/station_locator/data/models/station_marker.dart';

/// Route names for type-safe navigation
class AppRoutes {
  static const splash = '/';
  static const auth = '/auth';
  static const profileSetup = '/profile-setup';
  static const home = '/home';
  static const profile = '/profile';
  static const schedule = '/schedule';
  static const scan = '/scan';
  static const payment = '/payment';
  static const batterySwapStations = '/battery-swap-stations';
  static const evChargingStations = '/ev-charging-stations';
  static const stationDetails = '/station-details';
}

/// Main app router with auth redirect guards
class AppRouter {
  /// Create router with auth state listener for redirects
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      refreshListenable: _AuthStateRefreshListenable(authBloc),
      redirect: (context, state) => _guardRoute(authBloc, state),
      routes: [
        // Splash screen - initial route
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth route - triggers anonymous sign-in
        GoRoute(
          path: AppRoutes.auth,
          builder: (context, state) => const AuthWrapper(),
        ),

        // Profile setup - for authenticated users with incomplete profile
        GoRoute(
          path: AppRoutes.profileSetup,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: const ProfileSetupPage(),
          ),
        ),

        // Main app routes - require authenticated + complete profile
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => getIt<RequestBloc>()..add(const LoadIncomingRequests()),
              child: const HomePage(),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ProfileBloc>()..add(const LoadProfileRequested()),
            child: const ProfileScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.schedule,
          builder: (context, state) => const ScheduleScreen(),
        ),
        GoRoute(
          path: AppRoutes.scan,
          builder: (context, state) => const QRScannerScreen(),
        ),
        GoRoute(
          path: AppRoutes.payment,
          builder: (context, state) => const NFCPaymentScreen(amount: 0),
        ),

        // Station Locator routes
        GoRoute(
          path: AppRoutes.batterySwapStations,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<StationLocatorBloc>()
              ..add(const LoadNearbyStations(stationType: 'battery_swap')),
            child: const StationLocatorPage(stationType: 'battery_swap'),
          ),
        ),
        GoRoute(
          path: AppRoutes.evChargingStations,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<StationLocatorBloc>()
              ..add(const LoadNearbyStations(stationType: 'ev_charging')),
            child: const StationLocatorPage(stationType: 'ev_charging'),
          ),
        ),
        
        // Station details route
        GoRoute(
          path: '${AppRoutes.stationDetails}/:stationType/:stationId',
          builder: (context, state) {
            final stationType = state.pathParameters['stationType'] ?? 'battery_swap';
            final station = state.extra as StationMarker?;
            
            if (station == null) {
              // Fallback if station not passed
              return const Scaffold(
                body: Center(child: Text('Station not found')),
              );
            }
            
            return StationDetailsPage(
              station: station,
              stationType: stationType,
            );
          },
        ),
      ],
    );
  }

  /// Auth redirect guard logic
  /// 
  /// Redirects based on authentication and profile completion status:
  /// - Not authenticated → /auth
  /// - Authenticated but incomplete profile → /profile-setup
  /// - Fully authenticated → /home (if on auth/setup pages)
  static String? _guardRoute(AuthBloc authBloc, GoRouterState state) {
    final authState = authBloc.state;
    final currentPath = state.matchedLocation;

    // Public routes that don't require auth
    const publicRoutes = [AppRoutes.splash, AppRoutes.auth];
    final isPublicRoute = publicRoutes.contains(currentPath);

    // Profile setup route (needs auth but not complete profile)
    final isProfileSetup = currentPath == AppRoutes.profileSetup;

    // Check auth status
    final isAuthenticated = authState.isAuthenticated;
    final needsProfileSetup = authState.needsProfileSetup;

    // If splash screen, let it handle its own navigation
    if (currentPath == AppRoutes.splash) {
      return null;
    }

    // Not authenticated → redirect to auth (unless already there)
    if (!isAuthenticated && !isPublicRoute) {
      return AppRoutes.auth;
    }

    // Authenticated but needs profile setup → redirect to setup
    if (isAuthenticated && needsProfileSetup && !isProfileSetup && !isPublicRoute) {
      return AppRoutes.profileSetup;
    }

    // Fully authenticated user on auth/setup pages → redirect to home
    if (isAuthenticated && !needsProfileSetup && (isPublicRoute || isProfileSetup)) {
      return AppRoutes.home;
    }

    // No redirect needed
    return null;
  }

  /// Legacy static router for backwards compatibility
  /// Note: This doesn't have auth guards - use createRouter() instead
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<RequestBloc>()..add(const LoadIncomingRequests()),
            child: const HomePage(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: const ProfileSetupPage(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const NFCPaymentScreen(amount: 0),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthWrapper(),
      ),
    ],
  );
}

/// Listenable that triggers router refresh when auth state changes
class _AuthStateRefreshListenable extends ChangeNotifier {
  _AuthStateRefreshListenable(AuthBloc authBloc) {
    authBloc.stream.listen((_) => notifyListeners());
  }
}

