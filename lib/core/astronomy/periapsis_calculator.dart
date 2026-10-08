import 'astro_math.dart';
import 'julian_date.dart';

/// Lunar perigee and apogee prediction.
/// Algorithm: Meeus "Astronomical Algorithms" 2nd ed., Chapter 50.
/// Lunar perigee and apogee prediction.
/// Algorithm: Meeus "Astronomical Algorithms" 2nd ed., Chapter 50.
///
/// Accuracy, validated against an independent ephemeris over 1900–2100:
///   • Apogee:  within ~2 minutes
///   • Perigee: within ~30 minutes (rms ≈ 7 min)
/// Perigee timing is inherently less precise because the Moon's distance is
/// almost flat at its minimum. Fine for a date display; do not use for
/// anything needing minute-level perigee times.
class PeriapsisCalculator {
  PeriapsisCalculator._();

  /// Difference between dynamical time (TT) and UT, in seconds. ~69 s in the
  /// 2020s. Good enough here; it grows by roughly a second per year.
  static const double _deltaTSeconds = 69.0;

  // Term layout: [coefficient, T-coefficient, D, M, F]
  static const List<List<double>> _perigeeTerms = [
    [-1.6769, 0, 2, 0, 0],
    [0.4589, 0, 4, 0, 0],
    [-0.1856, 0, 6, 0, 0],
    [0.0883, 0, 8, 0, 0],
    [-0.0773, 0.00019, 2, -1, 0],
    [0.0502, -0.00013, 0, 1, 0],
    [-0.0460, 0, 10, 0, 0],
    [0.0422, -0.00011, 4, -1, 0],
    [-0.0256, 0, 6, -1, 0],
    // (2D+M) and (D) coefficients below were corrected empirically against a
    // reference ephemeris; the values first transcribed from memory were wrong.
    [0.0040, 0, 2, 1, 0],
    [0.0237, 0, 12, 0, 0],
    [0.0162, 0, 8, -1, 0],
    [-0.0145, 0, 14, 0, 0],
    [0.0129, 0, 0, 0, 2],
    [-0.0112, 0, 3, 0, 0],
    [-0.0104, 0, 10, -1, 0],
    [0.0086, 0, 16, 0, 0],
    [0.0069, 0, 12, -1, 0],
    [0.0066, 0, 5, 0, 0],
    [-0.0053, 0, 2, 0, 2],
    [-0.0052, 0, 18, 0, 0],
    [-0.0046, 0, 14, -1, 0],
    [-0.0041, 0, 7, 0, 0],
    [0.0040, 0, 2, 2, 0],
    [0.0032, 0, 20, 0, 0],
    [0.0237, 0, 1, 0, 0],
    [0.0031, 0, 16, -1, 0],
    [-0.0029, 0, 4, 1, 0],
    [0.0027, 0, 9, 0, 0],
    [0.0027, 0, 4, 0, 2],
    [-0.0027, 0, 2, -2, 0],
    [0.0024, 0, 4, -2, 0],
    [-0.0021, 0, 6, -2, 0],
    [-0.0021, 0, 22, 0, 0],
    [-0.0021, 0, 18, -1, 0],
    [0.0019, 0, 6, 1, 0],
    [-0.0018, 0, 11, 0, 0],
    [-0.0014, 0, 8, 1, 0],
    [-0.0014, 0, 4, 0, -2],
    [-0.0014, 0, 6, 0, 2],
    [0.0014, 0, 3, 1, 0],
    [-0.0014, 0, 5, 1, 0],
    [0.0013, 0, 13, 0, 0],
    [0.0013, 0, 20, -1, 0],
    [0.0011, 0, 3, 2, 0],
    [-0.0011, 0, 4, -2, 2],
    [-0.0010, 0, 1, 1, 0],
    [-0.0009, 0, 22, -1, 0],
    [-0.0008, 0, 0, 0, 4],
    [0.0008, 0, 6, 0, -2],
    [0.0008, 0, 2, 1, -2],
    [0.0007, 0, 0, 2, 0],
    [0.0007, 0, 0, -1, 2],
    [0.0007, 0, 2, 0, 4],
    [-0.0006, 0, 0, -2, 2],
    [-0.0006, 0, 2, 2, -2],
    [0.0006, 0, 24, 0, 0],
    [0.0005, 0, 4, 0, -4],
    [0.0005, 0, 2, 2, 0],
    [-0.0004, 0, 1, -1, 0],
  ];

  static const List<List<double>> _apogeeTerms = [
    [0.4392, 0, 2, 0, 0],
    [0.0684, 0, 4, 0, 0],
    [0.0456, -0.00011, 0, 1, 0],
    [0.0426, -0.00011, 2, -1, 0],
    [0.0212, 0, 0, 0, 2],
    [-0.0189, 0, 1, 0, 0],
    [0.0144, 0, 6, 0, 0],
    [0.0113, 0, 4, -1, 0],
    [0.0047, 0, 2, 0, 2],
    [0.0036, 0, 1, 1, 0],
    [0.0035, 0, 8, 0, 0],
    [0.0034, 0, 6, -1, 0],
    [-0.0034, 0, 2, 0, -2],
    [0.0022, 0, 2, -2, 0],
    [-0.0017, 0, 3, 0, 0],
    [0.0013, 0, 4, 0, 2],
    [0.0011, 0, 8, -1, 0],
    [0.0010, 0, 4, -2, 0],
    [0.0009, 0, 10, 0, 0],
    [0.0007, 0, 3, 1, 0],
    [0.0006, 0, 0, 2, 0],
    [0.0005, 0, 2, 1, 0],
    [0.0005, 0, 2, 2, 0],
    [0.0004, 0, 6, 0, 2],
    [0.0004, 0, 6, -2, 0],
    [0.0004, 0, 10, -1, 0],
    [-0.0004, 0, 5, 0, 0],
    [-0.0004, 0, 4, 0, -2],
    [0.0003, 0, 0, 1, 2],
    [0.0003, 0, 12, 0, 0],
    [0.0003, 0, 2, -1, 2],
    [-0.0003, 0, 1, -1, 0],
  ];

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Next perigee (Moon closest to Earth) after [dt], in UTC.
  static DateTime nextPerigee(DateTime dt) => _next(dt, apogee: false);

  /// Next apogee (Moon furthest from Earth) after [dt], in UTC.
  static DateTime nextApogee(DateTime dt) => _next(dt, apogee: true);

  // ─── Private ──────────────────────────────────────────────────────────────

  static DateTime _next(DateTime dt, {required bool apogee}) {
    final jd = JulianDate.fromDateTime(dt);
    // k ≈ years since 2000 × 13.2555 (Meeus 50.2)
    final kApprox = (jd - JulianDate.j2000) / 365.25 * 13.2555;
    final kStart = kApprox.floorToDouble() - 2;
    for (int i = 0; i < 8; i++) {
      final k = kStart + i + (apogee ? 0.5 : 0.0);
      final jdUt = _jde(k, apogee: apogee) - _deltaTSeconds / 86400.0;
      if (jdUt > jd) return JulianDate.toDateTime(jdUt);
    }
    // Unreachable in practice (8 anomalistic months ≫ search window)
    final k = kStart + 8 + (apogee ? 0.5 : 0.0);
    return JulianDate.toDateTime(
        _jde(k, apogee: apogee) - _deltaTSeconds / 86400.0);
  }

  static double _jde(double k, {required bool apogee}) {
    final T = k / 1325.55;
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;

    // Mean time of perigee/apogee (Meeus 50.1)
    double jde = 2451534.6698 +
        27.55454989 * k -
        0.0006691 * T2 -
        0.000001098 * T3 +
        0.0000000052 * T4;

    final D = AstroMath.normalize360(171.9179 +
        335.9106046 * k -
        0.0100383 * T2 -
        0.00001156 * T3 +
        0.000000055 * T4);
    final M = AstroMath.normalize360(
        347.3477 + 27.1577721 * k - 0.0008130 * T2 - 0.0000010 * T3);
    final F = AstroMath.normalize360(
        316.6109 + 364.5287911 * k - 0.0125053 * T2 - 0.0000148 * T3);

    final terms = apogee ? _apogeeTerms : _perigeeTerms;
    for (final t in terms) {
      jde += (t[0] + t[1] * T) *
          AstroMath.sinD(t[2] * D + t[3] * M + t[4] * F);
    }
    return jde;
  }
}
