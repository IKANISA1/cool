import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ridelink/core/config/env_config.dart';
import 'package:ridelink/core/error/error_handler.dart';
import 'package:ridelink/core/error/exceptions.dart';
import 'package:ridelink/core/theme/app_theme.dart';
import 'package:ridelink/core/router/app_router.dart';
import 'package:ridelink/core/di/injection.dart';
import 'package:ridelink/core/widgets/config_error_screen.dart';
import 'package:ridelink/features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Global Error Handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorHandler.logException(
      details.exception,
      stackTrace: details.stack,
      context: 'FlutterError',
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorHandler.logException(error, stackTrace: stack, context: 'PlatformDispatcher');
    return true;
  };

  try {
    // Load and validate environment variables
    await EnvConfig.init();
    
    // Initialize Supabase and Dependencies
    await configureDependencies();
    
    runApp(const RideLinkApp());
  } on ConfigurationException catch (e) {
    // Show configuration error screen
    ErrorHandler.logException(e, context: 'Configuration');
    runApp(ConfigErrorApp(exception: e));
  } catch (e, stack) {
    // Show generic error screen for unexpected startup errors
    ErrorHandler.logException(e, stackTrace: stack, context: 'Startup');
    runApp(ConfigErrorApp(
      exception: ConfigurationException(
        message: 'Failed to start app: ${e.toString()}',
      ),
    ));
  }
}

class RideLinkApp extends StatelessWidget {
  const RideLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        // Add other global blocs here
      ],
      child: MaterialApp.router(
        title: 'RideLink',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
