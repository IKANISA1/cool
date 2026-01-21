---
description: 
---

/ui-ux

Implement the complete UI/UX system for RideLink:

1. DESIGN SYSTEM
   - Create AppTheme class with:
     * Dark theme configuration
     * Primary gradient (Blue → Purple → Pink)
     * Typography system (Poppins font family)
     * Color palette
   - Implement GlassTheme utilities:
     * Blur values
     * Border radii
     * Shadow configurations

2. CORE WIDGETS (lib/shared/widgets/)
   Create the following reusable components:
   
   a) GlassCard
      - Backdrop blur effect
      - Gradient background
      - Border with opacity
      - Shadow
      - onTap handler
   
   b) GlassButton
      - Scale animation on press
      - Loading state
      - Haptic feedback integration
      - Customizable colors
   
   c) GlassTextField
      - Transparent background
      - Icon support (prefix/suffix)
      - Validation
      - Error states
   
   d) CountdownTimer
      - Animated circular progress
      - Real-time countdown
      - OnComplete callback
   
   e) UserAvatar
      - Online status indicator
      - Verification badge
      - Gradient background
      - Image support
   
   f) VehicleIcon
      - Dynamic icon based on vehicle type
      - Customizable size/color
   
   g) ShimmerPlaceholder
      - Skeleton loading
      - Configurable dimensions
   
   h) GlassBottomNav
      - Icon + label items
      - Active state
      - Smooth transitions
   
   i) LoadingOverlay
      - Full-screen blur
      - Loading indicator
      - Optional message

3. SCREENS (Complete UI implementation)
   
   a) SplashScreen
      - Animated logo
      - Scale + fade animations
      - Auto-navigate after 2s
   
   b) AuthScreen
      - Phone input step
      - OTP verification step
      - WhatsApp branding
      - Error handling UI
   
   c) ProfileSetupScreen
      - Role selection (Driver/Passenger)
      - Vehicle type grid (for drivers)
      - Country dropdown
      - Name input
      - Form validation
   
   d) HomeScreen
      - Header with profile avatar
      - Online/offline toggle
      - Search bar
      - Driver/Passenger tabs
      - Nearby users list
      - Distance, rating, verification badges
      - Bottom navigation
   
   e) RequestModal (Bottom Sheet)
      - User info display
      - 60-second countdown
      - Progress bar
      - Accept/Deny buttons
      - WhatsApp handoff
   
   f) ScheduleScreen
      - Mode toggle (Structured/AI)
      - Structured form:
        * Date/time picker
        * Origin/destination inputs
        * Seats counter
        * Vehicle preference
      - AI mode:
        * Voice button
        * Text input
        * Parsed result display
        * Suggestions
   
   g) ProfileScreen
      - User stats (rides, rating, accept rate)
      - Quick actions
      - Settings
      - Sign out
   
   h) QRScannerScreen
      - Camera viewfinder
      - Scan frame animation
      - Manual input option
      - QR code generation
   
   i) NFCScreen
      - Read/Write mode toggle
      - NFC status indicators
      - Mobile Money options
      - Transaction flow

4. ANIMATIONS
   - Implement flutter_animate for:
     * Screen transitions
     * Card reveals
     * Shimmer effects
     * Countdown animations
   - Add Lottie animations:
     * Loading states
     * Success/error feedback
     * Empty states

5. RESPONSIVE DESIGN
   - Media query utilities
   - Breakpoint constants
   - Adaptive layouts for tablets

6. ACCESSIBILITY
   - Semantic labels
   - Screen reader support
   - High contrast mode
   - Touch target sizes (minimum 48x48)

Testing:
- Run on iOS Simulator
- Run on Android Emulator
- Test all screen transitions
- Verify animations at 60fps
- Test with VoiceOver/TalkBack

Artifacts:
- Screenshot of each screen
- Video recording of navigation flow
- Design system documentation
- Widget catalog