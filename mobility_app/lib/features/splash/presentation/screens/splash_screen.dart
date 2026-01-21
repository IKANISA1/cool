import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/core/theme/app_theme.dart';
import 'package:ridelink/features/auth/presentation/bloc/auth_bloc.dart';

/// Premium splash screen with smooth animated transition to home
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _transitionController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textSlide;
  late Animation<double> _textFade;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  bool _isTransitioning = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Main logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Exit transition controller
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Logo scale with elastic bounce
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_logoController);

    // Logo fade in
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Text slide up
    _textSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Text fade in
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Exit animations
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInCubic,
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeInCubic,
      ),
    );
  }

  void _startAnimationSequence() {
    // Start logo animation
    _logoController.forward();

    // Trigger auth after animation starts
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    setState(() => _isTransitioning = true);
    
    // Play exit animation then navigate
    _transitionController.forward().then((_) {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  void _navigateToProfileSetup() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    setState(() => _isTransitioning = true);
    
    _transitionController.forward().then((_) {
      if (mounted) {
        context.go('/profile-setup');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.step == AuthFlowStep.authenticated) {
          // Wait a bit for visual polish, then navigate
          Future.delayed(const Duration(milliseconds: 300), () {
            if (state.needsProfileSetup) {
              _navigateToProfileSetup();
            } else {
              _navigateToHome();
            }
          });
        }
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([_logoController, _transitionController]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _isTransitioning 
                  ? _exitFade 
                  : const AlwaysStoppedAnimation(1.0),
              child: Transform.scale(
                scale: _isTransitioning ? _exitScale.value : 1.0,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGradient.colors.first,
                        AppTheme.primaryGradient.colors.last,
                        Color.fromARGB(
                          (AppTheme.primaryGradient.colors.last.a * 255).round().clamp(0, 255),
                          (AppTheme.primaryGradient.colors.last.r * 255).round().clamp(0, 255),
                          (AppTheme.primaryGradient.colors.last.g * 255).round().clamp(0, 255),
                          (AppTheme.primaryGradient.colors.last.b * 0.8 * 255).round().clamp(0, 255),
                        ),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // Decorative background elements
                        ..._buildBackgroundElements(screenSize),
                        
                        // Main content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo with animations
                              FadeTransition(
                                opacity: _logoFade,
                                child: ScaleTransition(
                                  scale: _logoScale,
                                  child: _buildLogo(isSmallScreen),
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 20 : 32),
                              
                              // App name
                              Transform.translate(
                                offset: Offset(0, _textSlide.value),
                                child: FadeTransition(
                                  opacity: _textFade,
                                  child: _buildAppName(isSmallScreen),
                                ),
                              ),
                              
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              
                              // Tagline
                              Transform.translate(
                                offset: Offset(0, _textSlide.value * 1.2),
                                child: FadeTransition(
                                  opacity: _textFade,
                                  child: _buildTagline(isSmallScreen),
                                ),
                              ),
                              
                              const SizedBox(height: 60),
                              
                              // Loading indicator
                              FadeTransition(
                                opacity: _textFade,
                                child: _buildLoadingIndicator(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundElements(Size screenSize) {
    return [
      // Top-right glow
      Positioned(
        top: -screenSize.height * 0.1,
        right: -screenSize.width * 0.2,
        child: Container(
          width: screenSize.width * 0.6,
          height: screenSize.width * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
      // Bottom-left glow
      Positioned(
        bottom: -screenSize.height * 0.15,
        left: -screenSize.width * 0.3,
        child: Container(
          width: screenSize.width * 0.8,
          height: screenSize.width * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildLogo(bool isSmallScreen) {
    final size = isSmallScreen ? 100.0 : 130.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.directions_car_rounded,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppName(bool isSmallScreen) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Colors.white70],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: Text(
        'RideLink',
        style: TextStyle(
          fontSize: isSmallScreen ? 36 : 48,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Text(
        'AI-First Mobility',
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
