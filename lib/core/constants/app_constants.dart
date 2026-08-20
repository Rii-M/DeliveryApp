import 'dart:ui' show Color;

class AppConstants {
  AppConstants._();

  static const String appName = 'POS Delivery';
  static const String driverName = 'Ram Sharma';

  static const String defaultCurrency = 'Rs.';

  static const Duration syncDelay = Duration(seconds: 2);

  static const double cardBorderRadius = 16;
  static const double smallBorderRadius = 8;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;

  /// Dashboard accent palettes (tonal icon pairs: light bg + saturated icon).
  static const Color tealGreenIcon = Color(0xFF4B7A5B);
  static const Color tealGreenBg = Color(0xFFE7F0E9);
  static const Color indigoIcon = Color(0xFF24487A);
  static const Color indigoBg = Color(0xFFE4EAF3);
  static const Color rustIcon = Color(0xFFB4482E);
  static const Color rustBg = Color(0xFFF7E6E1);
  static const Color violetIcon = Color(0xFF6B4C7A);
  static const Color violetBg = Color(0xFFEFE7F2);
  static const Color amberIcon = Color(0xFFE2992F);
  static const Color amberBg = Color(0xFFFBEEDA);
}
