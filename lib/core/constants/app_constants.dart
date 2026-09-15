import 'dart:ui' show Color;

class AppConstants {
  AppConstants._();

  static const String appName = 'POS Sales';
  static const String driverName = 'Ram Sharma';

  static const String defaultCurrency = 'Rs.';

  static const Duration syncDelay = Duration(seconds: 2);

  static const double cardBorderRadius = 16;
  static const double smallBorderRadius = 8;
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;

  /// Dashboard accent palettes (tonal icon pairs: light bg + saturated icon),
  /// kept within the warm brand family so the dashboard stays cohesive and
  /// professional rather than multi-coloured.
  static const Color tealGreenIcon = Color(0xFF2E8B6A);
  static const Color tealGreenBg = Color(0xFFD4F0E4);
  static const Color indigoIcon = Color(0xFFD4952A);
  static const Color indigoBg = Color(0xFFFFF0D6);
  static const Color rustIcon = Color(0xFFEF5330);
  static const Color rustBg = Color(0xFFFFDDD3);
  static const Color violetIcon = Color(0xFF8D6E63);
  static const Color violetBg = Color(0xFFEFDDD0);
  static const Color amberIcon = Color(0xFFFF9100);
  static const Color amberBg = Color(0xFFFFF3E0);
}
