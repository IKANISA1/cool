import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/bloc/app/app_bloc.dart';
import 'core/bloc/app/app_event.dart';
import 'core/bloc/app/app_state.dart';

import 'core/config/route_config.dart';
import 'core/config/theme_config.dart';
import 'core/di/injection.dart';

/// Root application widget
class MobilityApp extends StatelessWidget {
  const MobilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) => getIt<AppBloc>()..add(const AppStarted()),
        ),
        // Add other global blocs here
      ],
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Mobility',
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: _getThemeMode(state.themeMode),

            // Routing
            initialRoute: RouteConfig.splash,
            routes: RouteConfig.routes,
            onGenerateRoute: RouteConfig.onGenerateRoute,

            // Error handling
            builder: (context, child) {
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
