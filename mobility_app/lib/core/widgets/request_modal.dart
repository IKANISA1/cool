import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/requests/domain/entities/ride_request.dart';
import 'countdown_timer.dart';
import 'glassmorphic_card.dart';
import 'user_avatar.dart';
import 'rating_stars.dart';
import 'vehicle_icon.dart';

/// Full-screen glassmorphic modal for incoming ride requests
///
/// Features:
/// - Backdrop blur with dark overlay
/// - 60-second countdown timer with pulse animation
/// - Sender info with avatar, rating, and vehicle
/// - Accept/Decline buttons with haptic feedback
/// - Optional note display
class RequestModal extends StatefulWidget {
  /// The incoming ride request
  final RideRequest request;

  /// Callback when request is accepted
  final VoidCallback onAccept;

  /// Callback when request is declined
  final VoidCallback onDecline;

  /// Callback when countdown expires
  final VoidCallback? onExpire;

  const RequestModal({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    this.onExpire,
  });

  /// Show the modal as a full-screen overlay
  static Future<bool?> show(
    BuildContext context, {
    required RideRequest request,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    VoidCallback? onExpire,
  }) {
    HapticFeedback.mediumImpact();
    
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return RequestModal(
          request: request,
          onAccept: onAccept,
          onDecline: onDecline,
          onExpire: onExpire,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<RequestModal> createState() => _RequestModalState();
}

class _RequestModalState extends State<RequestModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int _remainingSeconds = 60;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.request.secondsRemaining;
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleAccept() {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
    widget.onAccept();
  }

  void _handleDecline() {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(false);
    widget.onDecline();
  }

  void _handleExpire() {
    if (_isResponding) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(null);
    widget.onExpire?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final sender = widget.request.fromUser;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Glassmorphic backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Prevent dismiss on tap
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Incoming Request',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Someone wants to ride with you',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main card
                    GlassmorphicCard(
                      blur: 20,
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Countdown timer
                          CountdownTimer(
                            totalSeconds: 60,
                            remainingSeconds: _remainingSeconds,
                            size: 100,
                            strokeWidth: 8,
                            onTick: (seconds) {
                              setState(() => _remainingSeconds = seconds);
                            },
                            onComplete: _handleExpire,
                          ),
                          const SizedBox(height: 24),

                          // Sender info
                          if (sender != null) ...[
                            UserAvatar(
                              initials: sender.name.isNotEmpty 
                                  ? sender.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
                                  : '?',
                              imageUrl: sender.avatarUrl,
                              size: 80,
                              isOnline: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              sender.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingStars(
                                  rating: sender.rating,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sender.rating.toStringAsFixed(1),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (sender.vehicleCategory != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  VehicleIcon(
                                    category: sender.vehicleCategory!,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatVehicleCategory(sender.vehicleCategory!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            // Fallback if no sender info
                            const Icon(
                              Icons.person,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unknown User',
                              style: theme.textTheme.titleLarge,
                            ),
                          ],

                          // Optional note
                          if (widget.request.note != null &&
                              widget.request.note!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.request.note!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    SizedBox(
                      width: size.width * 0.8,
                      child: Row(
                        children: [
                          // Decline button
                          Expanded(
                            child: _ActionButton(
                              label: 'Decline',
                              icon: Icons.close_rounded,
                              color: theme.colorScheme.error,
                              onPressed: _isResponding ? null : _handleDecline,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Accept button
                          Expanded(
                            child: _ActionButton(
                              label: 'Accept',
                              icon: Icons.check_rounded,
                              color: theme.colorScheme.primary,
                              isPrimary: true,
                              onPressed: _isResponding ? null : _handleAccept,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVehicleCategory(String category) {
    switch (category.toLowerCase()) {
      case 'moto':
        return 'Motorcycle';
      case 'cab':
        return 'Taxi Cab';
      case 'liffan':
        return 'Liffan';
      case 'truck':
        return 'Truck';
      case 'rent':
        return 'Rental';
      default:
        return category;
    }
  }
}

/// Animated action button with glassmorphic style
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isPrimary = false,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: widget.isPrimary
                    ? widget.color.withValues(alpha: isDisabled ? 0.3 : 0.9)
                    : Colors.white.withValues(alpha: isDisabled ? 0.05 : 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isPrimary
                      ? widget.color.withValues(alpha: 0.5)
                      : widget.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isPrimary
                        ? Colors.white
                        : (isDisabled ? widget.color.withValues(alpha: 0.5) : widget.color),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: widget.isPrimary
                          ? Colors.white
                          : (isDisabled ? widget.color.withValues(alpha: 0.5) : widget.color),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
