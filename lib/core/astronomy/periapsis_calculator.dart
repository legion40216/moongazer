import 'astro_math.dart';
import 'julian_date.dart';

/// Lunar perigee and apogee prediction.
/// Algorithm: Meeus "Astronomical Algorithms" 2nd ed., Chapter 50.
class PeriapsisCalculator {
  PeriapsisCalculator._();

  static const double _anomMonth = 27.55454989; // mean anomalistic month

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Next perigee (Moon closest to Earth) after [dt].
  static DateTime nextPerigee(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    final kBase = _kFor(jd).floorToDouble();
    for (int i = 0; i < 6; i++) {
      final jde = _perigeeJde(kBase + i);
      if (jde > jd) return JulianDate.toDateTime(jde);
    }
    return JulianDate.toDateTime(_perigeeJde(kBase + 6));
  }

  /// Next apogee (Moon furthest from Earth) after [dt].
  static DateTime nextApogee(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    final kBase = _kFor(jd).floorToDouble();
    for (int i = 0; i < 6; i++) {
      final jde = _apogeeJde(kBase + i);
      if (jde > jd) return JulianDate.toDateTime(jde);
    }
    return JulianDate.toDateTime(_apogeeJde(kBase + 6));
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static double _kFor(double jd) =>
      JulianDate.julianCenturies(jd) * 1325.55;

  // Base JDE for a given k (integer = perigee, integer+0.5 = apogee)
  static double _baseJde(double k) {
    final T = k / 1325.55;
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;
    return 2451534.6408 +
        _anomMonth * k -
        0.0006691 * T2 -
        0.000001098 * T3 +
        0.0000000052 * T4;
  }

  static double _perigeeJde(double kInt) {
    final T = kInt / 1325.55;
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;

    var jde = _baseJde(kInt);

    final D = AstroMath.normalize360(
        171.9179 + 335.9106046 * kInt - 0.0100383 * T2 - 0.00001156 * T3 + 0.000000055 * T4);
    final M = AstroMath.normalize360(
        347.3477 + 27.1577721 * kInt - 0.0008130 * T2 - 0.0000010 * T3);
    final F = AstroMath.normalize360(
        316.6109 + 364.5287911 * kInt - 0.0125053 * T2 - 0.0000148 * T3);

    // Meeus Table 50.a – perigee corrections
    jde += -1.6769 * AstroMath.sinD(2 * D) +
        0.4589 * AstroMath.sinD(4 * D) -
        0.1856 * AstroMath.sinD(6 * D) +
        0.1143 * AstroMath.sinD(8 * D) -
        0.0728 * AstroMath.sinD(2 * D - M) -
        0.0337 * AstroMath.sinD(10 * D) -
        0.0208 * AstroMath.sinD(M) -
        0.0108 * AstroMath.sinD(12 * D) +
        0.0085 * AstroMath.sinD(3 * M) +
        0.0079 * AstroMath.sinD(16 * D) -
        0.0038 * AstroMath.sinD(2 * D + M) +
        0.0033 * AstroMath.sinD(18 * D) -
        0.0026 * AstroMath.sinD(2 * D - 2 * M) +
        0.0028 * AstroMath.sinD(2 * M) +
        0.0004 * AstroMath.sinD(20 * D) +
        0.0018 * AstroMath.sinD(4 * D - M) +
        0.0024 * AstroMath.sinD(2 * (2 * D - M)) -
        0.0015 * AstroMath.sinD(2 * (D + M)) +
        0.0022 * AstroMath.sinD(4 * D + M) -
        0.0006 * AstroMath.sinD(24 * D) -
        0.0010 * AstroMath.sinD(4 * (D - M)) +
        0.0004 * AstroMath.sinD(2 * D - 3 * M) +
        0.0105 * AstroMath.sinD(2 * F - 2 * D) +
        0.0046 * AstroMath.sinD(2 * F - 4 * D) -
        0.0088 * AstroMath.sinD(2 * D + 2 * F);
    return jde;
  }

  static double _apogeeJde(double kInt) {
    final kA = kInt + 0.5; // apogee is half-integer k
    final T = kA / 1325.55;
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;

    var jde = _baseJde(kA);

    final D = AstroMath.normalize360(
        171.9179 + 335.9106046 * kA - 0.0100383 * T2 - 0.00001156 * T3 + 0.000000055 * T4);
    final M = AstroMath.normalize360(
        347.3477 + 27.1577721 * kA - 0.0008130 * T2 - 0.0000010 * T3);
    final F = AstroMath.normalize360(
        316.6109 + 364.5287911 * kA - 0.0125053 * T2 - 0.0000148 * T3);

    // Meeus Table 50.b – apogee corrections
    jde += -0.4392 * AstroMath.sinD(2 * D) +
        0.0684 * AstroMath.sinD(M) +
        0.0456 * AstroMath.sinD(4 * D) -
        0.0367 * AstroMath.sinD(2 * D - M) -
        0.0311 * AstroMath.sinD(2 * D + M) +
        0.0021 * AstroMath.sinD(6 * D) +
        0.0021 * AstroMath.sinD(2 * M) -
        0.0006 * AstroMath.sinD(2 * (D + M)) -
        0.0006 * AstroMath.sinD(2 * M + 2 * D) +
        0.0005 * AstroMath.sinD(2 * M - 2 * D) +
        0.0293 * AstroMath.sinD(2 * F - 2 * D) +
        0.0058 * AstroMath.sinD(2 * F - 4 * D) -
        0.0015 * AstroMath.sinD(2 * F + 2 * D) -
        0.0010 * AstroMath.sinD(2 * M - 2 * F) +
        0.0065 * AstroMath.sinD(2 * F - M - 2 * D);
    return jde;
  }
}
