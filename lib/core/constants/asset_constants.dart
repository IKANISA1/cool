/// Asset path constants
class AssetConstants {
  AssetConstants._();

  // ═══════════════════════════════════════════════════════════
  // BASE PATHS
  // ═══════════════════════════════════════════════════════════

  static const String _images = 'assets/images';
  static const String _animations = 'assets/animations';
  static const String _icons = 'assets/images/icons';
  static const String _onboarding = 'assets/images/onboarding';

  // ═══════════════════════════════════════════════════════════
  // LOGO & BRANDING
  // ═══════════════════════════════════════════════════════════

  static const String logo = '$_images/logo.png';
  static const String logoLight = '$_images/logo_light.png';
  static const String logoDark = '$_images/logo_dark.png';

  // ═══════════════════════════════════════════════════════════
  // ONBOARDING IMAGES
  // ═══════════════════════════════════════════════════════════

  static const String onboarding1 = '$_onboarding/onboarding_1.png';
  static const String onboarding2 = '$_onboarding/onboarding_2.png';
  static const String onboarding3 = '$_onboarding/onboarding_3.png';

  // ═══════════════════════════════════════════════════════════
  // ICONS
  // ═══════════════════════════════════════════════════════════

  static const String iconMoto = '$_icons/moto.svg';
  static const String iconCab = '$_icons/cab.svg';
  static const String iconTruck = '$_icons/truck.svg';
  static const String iconRent = '$_icons/rent.svg';
  static const String iconNfc = '$_icons/nfc.svg';
  static const String iconQr = '$_icons/qr.svg';

  // ═══════════════════════════════════════════════════════════
  // LOTTIE ANIMATIONS
  // ═══════════════════════════════════════════════════════════

  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/success.json';
  static const String errorAnimation = '$_animations/error.json';
  static const String emptyAnimation = '$_animations/empty.json';
  static const String locationAnimation = '$_animations/location.json';
  static const String searchAnimation = '$_animations/search.json';

  // ═══════════════════════════════════════════════════════════
  // PLACEHOLDERS
  // ═══════════════════════════════════════════════════════════

  static const String avatarPlaceholder = '$_images/avatar_placeholder.png';
  static const String vehiclePlaceholder = '$_images/vehicle_placeholder.png';
}
