import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/route_config.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../bloc/auth_bloc.dart';

/// Auth wrapper that manages automatic anonymous authentication
///
/// This widget listens to the auth bloc and automatically triggers
/// anonymous sign-in, then navigates to the appropriate screen.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Trigger anonymous sign-in on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthSignInAnonymouslyRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.step == AuthFlowStep.authenticated) {
          // Navigate to home or profile setup
          if (state.needsProfileSetup) {
            Navigator.of(context).pushReplacementNamed(RouteConfig.profileSetup);
          } else {
            Navigator.of(context).pushReplacementNamed(RouteConfig.home);
          }
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingIndicator(message: 'Setting up...'),
              const SizedBox(height: 24),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state.error != null) {
                    return Column(
                      children: [
                        Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                              const AuthSignInAnonymouslyRequested(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
