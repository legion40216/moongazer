import 'astro_math.dart';
import 'julian_date.dart';

/// Sun distance calculation.
/// Algorithm: Meeus "Astronomical Algorithms" 2nd ed., Chapter 25 (low-precision).
class SunCalculator {
  SunCalculator._();

  /// Sun-Earth distance in km for [dt].
  static double distanceKm(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    final T = JulianDate.julianCenturies(jd);

    // Sun's mean anomaly (degrees)
    final M = AstroMath.normalize360(
        357.5291092 + 35999.0502909 * T - 0.0001536 * T * T);

    // Equation of center
    final C = (1.9146 - 0.004817 * T - 0.000014 * T * T) * AstroMath.sinD(M) +
        (0.019993 - 0.000101 * T) * AstroMath.sinD(2 * M) +
        0.000290 * AstroMath.sinD(3 * M);

    // Sun's true anomaly
    final v = M + C;

    // Radius vector in AU (Meeus 25.4)
    final R = 1.000001018 *
        (1.0 - 0.016708634 * 0.016708634) /
        (1.0 + 0.016708634 * AstroMath.cosD(v));

    // 1 AU = 149,597,870.7 km
    return R * 149597870.7;
  }
}
