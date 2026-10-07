import 'dart:math' as math;

/// Shared astronomy math helpers used across all calculation modules.
class AstroMath {
  AstroMath._();

  static const double twoPi = 2 * math.pi;

  /// Degrees → radians
  static double toRad(double deg) => deg * math.pi / 180.0;

  /// Radians → degrees
  static double toDeg(double rad) => rad * 180.0 / math.pi;

  /// Sine of an angle in degrees
  static double sinD(double deg) => math.sin(toRad(deg));

  /// Cosine of an angle in degrees
  static double cosD(double deg) => math.cos(toRad(deg));

  /// Tangent of an angle in degrees
  static double tanD(double deg) => math.tan(toRad(deg));

  /// Arc-sine, result in degrees
  static double asinD(double x) => toDeg(math.asin(x));

  /// Arc-cosine, result in degrees
  static double acosD(double x) => toDeg(math.acos(x));

  /// Normalise an angle to [0, 360)
  static double normalize360(double angle) {
    double r = angle % 360.0;
    if (r < 0) r += 360.0;
    return r;
  }

  /// Normalise an angle to [0, 2π)
  static double normalize2pi(double angle) {
    double r = angle % twoPi;
    if (r < 0) r += twoPi;
    return r;
  }

  /// Integer floor of a double (mirrors Meeus notation INT())
  static int ifloor(double x) => x.floor();

  /// Format a distance in km with thousand separators
  static String formatKm(double km) {
    final rounded = km.round();
    final s = rounded.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()} km';
  }
}
