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
  static const Color tealGreenIcon = Color(0xFF3E6B52);
  static const Color tealGreenBg = Color(0xFFE8F2EC);
  static const Color indigoIcon = Color(0xFFA8722E);
  static const Color indigoBg = Color(0xFFF9EDD9);
  static const Color rustIcon = Color(0xFFD84315);
  static const Color rustBg = Color(0xFFFBE3D9);
  static const Color violetIcon = Color(0xFF795548);
  static const Color violetBg = Color(0xFFF3E9DF);
  static const Color amberIcon = Color(0xFFF58823);
  static const Color amberBg = Color(0xFFFFF0E0);
}
