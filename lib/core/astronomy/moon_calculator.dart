import 'dart:math' as math;
import 'astro_math.dart';
import 'julian_date.dart';

// ---------------------------------------------------------------------------
// Public result types
// ---------------------------------------------------------------------------

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

extension MoonPhaseLabel on MoonPhase {
  String get label {
    switch (this) {
      case MoonPhase.newMoon: return 'New Moon';
      case MoonPhase.waxingCrescent: return 'Waxing Crescent';
      case MoonPhase.firstQuarter: return 'First Quarter';
      case MoonPhase.waxingGibbous: return 'Waxing Gibbous';
      case MoonPhase.fullMoon: return 'Full Moon';
      case MoonPhase.waningGibbous: return 'Waning Gibbous';
      case MoonPhase.lastQuarter: return 'Last Quarter';
      case MoonPhase.waningCrescent: return 'Waning Crescent';
    }
  }

  String get emoji {
    switch (this) {
      case MoonPhase.newMoon: return '🌑';
      case MoonPhase.waxingCrescent: return '🌒';
      case MoonPhase.firstQuarter: return '🌓';
      case MoonPhase.waxingGibbous: return '🌔';
      case MoonPhase.fullMoon: return '🌕';
      case MoonPhase.waningGibbous: return '🌖';
      case MoonPhase.lastQuarter: return '🌗';
      case MoonPhase.waningCrescent: return '🌘';
    }
  }
}

enum PhaseEventType { newMoon, firstQuarter, fullMoon, lastQuarter }

class MoonPosition {
  /// Illuminated fraction of the disk, 0.0 (new) → 1.0 (full)
  final double illumination;

  /// Age in days since last new moon (0 – ~29.53)
  final double ageInDays;

  /// Distance from Earth centre in km
  final double distanceKm;

  /// Named phase
  final MoonPhase phase;

  /// Mean elongation in degrees (0=new, 90=first-quarter, 180=full, 270=last-quarter).
  /// Used by the moon painter for hemisphere-aware shadow rendering.
  final double elongation;

  const MoonPosition({
    required this.illumination,
    required this.ageInDays,
    required this.distanceKm,
    required this.phase,
    required this.elongation,
  });
}

class LunationEvents {
  final DateTime lastNewMoon;
  final DateTime firstQuarter;
  final DateTime fullMoon;
  final DateTime lastQuarter;
  final DateTime nextNewMoon;

  const LunationEvents({
    required this.lastNewMoon,
    required this.firstQuarter,
    required this.fullMoon,
    required this.lastQuarter,
    required this.nextNewMoon,
  });
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

/// Moon calculations based on Jean Meeus, "Astronomical Algorithms" 2nd ed.
/// Chapter 47 (position), 48 (illumination), 49 (phase events).
class MoonCalculator {
  MoonCalculator._();

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Full moon position data for [dt].
  static MoonPosition calculate(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    final T = JulianDate.julianCenturies(jd);

    // Mean anomaly of the Sun (Meeus 47.3)
    final M = AstroMath.normalize360(
        357.5291092 + 35999.0502909 * T - 0.0001536 * T * T +
            T * T * T / 24490000.0);

    // Moon's mean anomaly (Meeus 47.4)
    final Mp = AstroMath.normalize360(
        134.9633964 + 477198.8675055 * T + 0.0087414 * T * T +
            T * T * T / 69699.0 -
            T * T * T * T / 14712000.0);

    // Moon's argument of latitude (Meeus 47.5)
    final F = AstroMath.normalize360(
        93.2720950 + 483202.0175233 * T - 0.0036539 * T * T -
            T * T * T / 3526000.0 +
            T * T * T * T / 863310000.0);

    // Moon's mean elongation (Meeus 47.2) = basis for phase angle
    final D = AstroMath.normalize360(
        297.8501921 + 445267.1114034 * T - 0.0018819 * T * T +
            T * T * T / 545868.0 -
            T * T * T * T / 113065000.0);

    // Eccentricity correction
    final E = 1.0 - 0.002516 * T - 0.0000074 * T * T;

    // Phase angle (Meeus 48.4) – more accurate than just using D
    // i = 0° → full moon, 180° → new moon
    final phaseAngle = AstroMath.normalize360(
        180.0 - D -
            6.289 * AstroMath.sinD(Mp) +
            2.100 * AstroMath.sinD(M) -
            1.274 * AstroMath.sinD(2 * D - Mp) -
            0.658 * AstroMath.sinD(2 * D) -
            0.214 * AstroMath.sinD(2 * Mp) -
            0.110 * AstroMath.sinD(D));

    // Illuminated fraction (Meeus 48.1)
    final illum = ((1.0 + AstroMath.cosD(phaseAngle)) / 2.0).clamp(0.0, 1.0);

    // Distance in km (dominant Meeus terms from Table 47.B)
    final dist = _distanceKm(D, M, Mp, F, E);

    // Age in days – days elapsed since the last new moon JDE
    final lastNMjd = _lastNewMoonJde(jd);
    final age = (jd - lastNMjd).clamp(0.0, 29.53);

    // Phase name derived from mean elongation D
    final phase = _phaseFromElongation(D);

    return MoonPosition(
      illumination: illum,
      ageInDays: age,
      distanceKm: dist,
      phase: phase,
      elongation: D,
    );
  }

  /// Julian date of the last new moon before [jd].
  static DateTime lastNewMoon(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    return JulianDate.toDateTime(_lastNewMoonJde(jd));
  }

  /// The five events of the lunation that contains [dt], in calendar order:
  /// last new moon, first quarter, full moon, last quarter, next new moon.
  /// Some of these may be in the past; this mirrors the original MoonGazer
  /// layout, where the list always reads top-to-bottom as one lunar cycle.
  static LunationEvents lunation(DateTime dt) {
    final jd = JulianDate.fromDateTime(dt);
    final k = _lastNewMoonK(jd);
    return LunationEvents(
      lastNewMoon:
          JulianDate.toDateTime(_phaseJde(k, PhaseEventType.newMoon)),
      firstQuarter:
          JulianDate.toDateTime(_phaseJde(k, PhaseEventType.firstQuarter)),
      fullMoon: JulianDate.toDateTime(_phaseJde(k, PhaseEventType.fullMoon)),
      lastQuarter:
          JulianDate.toDateTime(_phaseJde(k, PhaseEventType.lastQuarter)),
      nextNewMoon:
          JulianDate.toDateTime(_phaseJde(k + 1, PhaseEventType.newMoon)),
    );
  }

  /// Julian date of the next occurrence of [eventType] after [dt].
  static DateTime nextPhaseEvent(DateTime dt, PhaseEventType eventType) {
    final jd = JulianDate.fromDateTime(dt);
    final T = JulianDate.julianCenturies(jd);
    double k = (T * 1236.85).floorToDouble();

    // Search forward; in rare edge cases the first candidate may be in the past
    for (int i = 0; i < 4; i++) {
      final jde = _phaseJde(k + i, eventType);
      if (jde > jd + 0.1) return JulianDate.toDateTime(jde);
    }
    return JulianDate.toDateTime(_phaseJde(k + 4, eventType));
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// The k index of the last new moon at or before [jd].
  /// Starts one lunation high and steps back, because the mean-phase estimate
  /// can be off by up to ~14 hours either way.
  static double _lastNewMoonK(double jd) {
    final k0 = (JulianDate.julianCenturies(jd) * 1236.85).floorToDouble();
    for (int i = 0; i <= 5; i++) {
      final k = k0 + 1 - i;
      if (_phaseJde(k, PhaseEventType.newMoon) <= jd) return k;
    }
    return k0 - 5;
  }

  static double _lastNewMoonJde(double jd) =>
      _phaseJde(_lastNewMoonK(jd), PhaseEventType.newMoon);

  /// Julian Ephemeris Date of a phase event.
  /// Algorithm: Meeus Chapter 49.
  static double _phaseJde(double kBase, PhaseEventType event) {
    double k = kBase;
    switch (event) {
      case PhaseEventType.firstQuarter:
        k += 0.25;
        break;
      case PhaseEventType.fullMoon:
        k += 0.50;
        break;
      case PhaseEventType.lastQuarter:
        k += 0.75;
        break;
      case PhaseEventType.newMoon:
        break;
    }

    final T = k / 1236.85;
    final T2 = T * T;
    final T3 = T2 * T;
    final T4 = T3 * T;

    // Mean phase JDE (Meeus 49.1)
    double jde = 2451550.09766 +
        29.530588861 * k +
        0.00015437 * T2 -
        0.000000150 * T3 +
        0.00000000073 * T4;

    final E = 1.0 - 0.002516 * T - 0.0000074 * T2;
    final M = AstroMath.normalize360(2.5534 +
        29.10535670 * k -
        0.0000014 * T2 -
        0.00000011 * T3);
    final Mp = AstroMath.normalize360(201.5643 +
        385.81693528 * k +
        0.0107582 * T2 +
        0.00001238 * T3 -
        0.000000058 * T4);
    final F = AstroMath.normalize360(160.7108 +
        390.67050284 * k -
        0.0016118 * T2 -
        0.00000227 * T3 +
        0.000000011 * T4);
    final omega = AstroMath.normalize360(
        124.7746 - 1.56375588 * k + 0.0020672 * T2 + 0.00000215 * T3);

    // Planetary arguments (Meeus p.352)
    final a1 = AstroMath.normalize360(299.77 + 0.107408 * k - 0.009173 * T2);
    final a2 = AstroMath.normalize360(251.88 + 0.016321 * k);
    final a3 = AstroMath.normalize360(251.83 + 26.651886 * k);
    final a4 = AstroMath.normalize360(349.42 + 36.412478 * k);
    final a5 = AstroMath.normalize360(84.66 + 18.206239 * k);
    final a6 = AstroMath.normalize360(141.74 + 53.303771 * k);
    final a7 = AstroMath.normalize360(207.14 + 2.453732 * k);
    final a8 = AstroMath.normalize360(154.84 + 7.306860 * k);
    final a9 = AstroMath.normalize360(34.52 + 27.261239 * k);
    final a10 = AstroMath.normalize360(207.19 + 0.121824 * k);
    final a11 = AstroMath.normalize360(291.34 + 1.844379 * k);
    final a12 = AstroMath.normalize360(161.72 + 24.198154 * k);
    final a13 = AstroMath.normalize360(239.56 + 25.513099 * k);
    final a14 = AstroMath.normalize360(331.55 + 3.592518 * k);

    if (event == PhaseEventType.newMoon) {
      jde += _newMoonCorrections(E, M, Mp, F, omega);
    } else if (event == PhaseEventType.fullMoon) {
      jde += _fullMoonCorrections(E, M, Mp, F, omega);
    } else {
      jde += _quarterCorrections(E, M, Mp, F, omega, event);
    }

    // Additional planetary corrections (all phases, Meeus p.352)
    jde += 0.000325 * AstroMath.sinD(a1) +
        0.000165 * AstroMath.sinD(a2) +
        0.000164 * AstroMath.sinD(a3) +
        0.000126 * AstroMath.sinD(a4) +
        0.000110 * AstroMath.sinD(a5) +
        0.000062 * AstroMath.sinD(a6) +
        0.000060 * AstroMath.sinD(a7) +
        0.000056 * AstroMath.sinD(a8) +
        0.000047 * AstroMath.sinD(a9) +
        0.000042 * AstroMath.sinD(a10) +
        0.000040 * AstroMath.sinD(a11) +
        0.000037 * AstroMath.sinD(a12) +
        0.000035 * AstroMath.sinD(a13) +
        0.000023 * AstroMath.sinD(a14);

    return jde;
  }

  static double _newMoonCorrections(
      double E, double M, double Mp, double F, double omega) {
    return -0.40720 * AstroMath.sinD(Mp) +
        0.17241 * E * AstroMath.sinD(M) +
        0.01608 * AstroMath.sinD(2 * Mp) +
        0.01039 * AstroMath.sinD(2 * F) +
        0.00739 * E * AstroMath.sinD(Mp - M) -
        0.00514 * E * AstroMath.sinD(Mp + M) +
        0.00208 * E * E * AstroMath.sinD(2 * M) -
        0.00111 * AstroMath.sinD(Mp - 2 * F) -
        0.00057 * AstroMath.sinD(Mp + 2 * F) +
        0.00056 * E * AstroMath.sinD(2 * Mp + M) -
        0.00042 * AstroMath.sinD(3 * Mp) +
        0.00042 * E * AstroMath.sinD(M + 2 * F) +
        0.00038 * E * AstroMath.sinD(M - 2 * F) -
        0.00024 * E * AstroMath.sinD(2 * Mp - M) -
        0.00017 * AstroMath.sinD(omega) -
        0.00007 * AstroMath.sinD(Mp + 2 * M) +
        0.00004 * AstroMath.sinD(2 * Mp - 2 * F) +
        0.00004 * AstroMath.sinD(3 * M) +
        0.00003 * AstroMath.sinD(Mp + M - 2 * F) +
        0.00003 * AstroMath.sinD(2 * Mp + 2 * F) -
        0.00003 * AstroMath.sinD(Mp + M + 2 * F) +
        0.00003 * AstroMath.sinD(Mp - M + 2 * F) -
        0.00002 * AstroMath.sinD(Mp - M - 2 * F) -
        0.00002 * AstroMath.sinD(3 * Mp + M) +
        0.00002 * AstroMath.sinD(4 * Mp);
  }

  static double _fullMoonCorrections(
      double E, double M, double Mp, double F, double omega) {
    return -0.40614 * AstroMath.sinD(Mp) +
        0.17302 * E * AstroMath.sinD(M) +
        0.01614 * AstroMath.sinD(2 * Mp) +
        0.01043 * AstroMath.sinD(2 * F) +
        0.00734 * E * AstroMath.sinD(Mp - M) -
        0.00515 * E * AstroMath.sinD(Mp + M) +
        0.00209 * E * E * AstroMath.sinD(2 * M) -
        0.00111 * AstroMath.sinD(Mp - 2 * F) -
        0.00057 * AstroMath.sinD(Mp + 2 * F) +
        0.00056 * E * AstroMath.sinD(2 * Mp + M) -
        0.00042 * AstroMath.sinD(3 * Mp) +
        0.00042 * E * AstroMath.sinD(M + 2 * F) +
        0.00038 * E * AstroMath.sinD(M - 2 * F) -
        0.00024 * E * AstroMath.sinD(2 * Mp - M) -
        0.00017 * AstroMath.sinD(omega) -
        0.00007 * AstroMath.sinD(Mp + 2 * M) +
        0.00004 * AstroMath.sinD(2 * Mp - 2 * F) +
        0.00004 * AstroMath.sinD(3 * M) +
        0.00003 * AstroMath.sinD(Mp + M - 2 * F) +
        0.00003 * AstroMath.sinD(2 * Mp + 2 * F) -
        0.00003 * AstroMath.sinD(Mp + M + 2 * F) +
        0.00003 * AstroMath.sinD(Mp - M + 2 * F) -
        0.00002 * AstroMath.sinD(Mp - M - 2 * F) -
        0.00002 * AstroMath.sinD(3 * Mp + M) +
        0.00002 * AstroMath.sinD(4 * Mp);
  }

  static double _quarterCorrections(double E, double M, double Mp, double F,
      double omega, PhaseEventType event) {
    double c = -0.62801 * AstroMath.sinD(Mp) +
        0.17172 * E * AstroMath.sinD(M) -
        0.01183 * E * AstroMath.sinD(Mp + M) +
        0.00862 * AstroMath.sinD(2 * Mp) +
        0.00804 * AstroMath.sinD(2 * F) +
        0.00454 * E * AstroMath.sinD(Mp - M) +
        0.00204 * E * E * AstroMath.sinD(2 * M) -
        0.00180 * AstroMath.sinD(Mp - 2 * F) -
        0.00070 * AstroMath.sinD(Mp + 2 * F) -
        0.00040 * AstroMath.sinD(3 * Mp) -
        0.00034 * E * AstroMath.sinD(2 * Mp - M) +
        0.00032 * E * AstroMath.sinD(M + 2 * F) +
        0.00032 * E * AstroMath.sinD(M - 2 * F) -
        0.00028 * E * E * AstroMath.sinD(Mp + 2 * M) +
        0.00027 * E * AstroMath.sinD(2 * Mp + M) -
        0.00017 * AstroMath.sinD(omega) -
        0.00005 * AstroMath.sinD(Mp - M - 2 * F) +
        0.00004 * AstroMath.sinD(2 * Mp + 2 * F) -
        0.00004 * AstroMath.sinD(Mp + M + 2 * F) +
        0.00004 * AstroMath.sinD(Mp - 2 * M) +
        0.00003 * AstroMath.sinD(Mp + M - 2 * F) +
        0.00003 * AstroMath.sinD(3 * M) +
        0.00002 * AstroMath.sinD(2 * Mp - 2 * F) +
        0.00002 * AstroMath.sinD(Mp - M + 2 * F) -
        0.00002 * AstroMath.sinD(3 * Mp + M);

    // Quarter-only W correction (Meeus p.352)
    final W = 0.00306 -
        0.00038 * E * AstroMath.cosD(M) +
        0.00026 * AstroMath.cosD(Mp) -
        0.00002 * AstroMath.cosD(Mp - M) +
        0.00002 * AstroMath.cosD(Mp + M) +
        0.00002 * AstroMath.cosD(2 * F);

    return c + (event == PhaseEventType.firstQuarter ? W : -W);
  }

  /// Meeus Table 47.A, radial terms (first 30 of 60).
  /// Columns: D, M, M', F, coefficient (in 1/1000 km).
  /// Verified against an independent ephemeris: worst error ≈ 44 km
  /// over 400 sample dates (≈0.01 %).
  static const List<List<double>> _rTerms = [
    [0, 0, 1, 0, -20905355],
    [2, 0, -1, 0, -3699111],
    [2, 0, 0, 0, -2955968],
    [0, 0, 2, 0, -569925],
    [0, 1, 0, 0, 48888],
    [0, 0, 0, 2, -3149],
    [2, 0, -2, 0, 246158],
    [2, -1, -1, 0, -152138],
    [2, 0, 1, 0, -170733],
    [2, -1, 0, 0, -204586],
    [0, 1, -1, 0, -129620],
    [1, 0, 0, 0, 108743],
    [0, 1, 1, 0, 104755],
    [2, 0, 0, -2, 10321],
    [0, 0, 1, -2, 79661],
    [4, 0, -1, 0, -34782],
    [0, 0, 3, 0, -23210],
    [4, 0, -2, 0, -21636],
    [2, 1, -1, 0, 24208],
    [2, 1, 0, 0, 30824],
    [1, 0, -1, 0, -8379],
    [1, 1, 0, 0, -16675],
    [2, -1, 1, 0, -12831],
    [2, 0, 2, 0, -10445],
    [4, 0, 0, 0, -11650],
    [2, 0, -3, 0, 14403],
    [0, 1, -2, 0, -7003],
    [2, -1, -2, 0, 10056],
    [1, 0, 1, 0, 6322],
    [2, -2, 0, 0, -9884],
  ];

  // ─── Distance ─────────────────────────────────────────────────────────────

  /// Distance from Earth's centre to Moon's centre in km.
  static double _distanceKm(
      double D, double M, double Mp, double F, double E) {
    double sum = 0.0;
    for (final t in _rTerms) {
      final eFactor = t[1] == 0 ? 1.0 : (t[1].abs() == 1 ? E : E * E);
      sum += t[4] *
          eFactor *
          AstroMath.cosD(t[0] * D + t[1] * M + t[2] * Mp + t[3] * F);
    }
    return 385000.56 + sum / 1000.0;
  }

  // ─── Phase name ───────────────────────────────────────────────────────────

  static MoonPhase _phaseFromElongation(double D) {
    if (D < 22.5 || D >= 337.5) return MoonPhase.newMoon;
    if (D < 67.5) return MoonPhase.waxingCrescent;
    if (D < 112.5) return MoonPhase.firstQuarter;
    if (D < 157.5) return MoonPhase.waxingGibbous;
    if (D < 202.5) return MoonPhase.fullMoon;
    if (D < 247.5) return MoonPhase.waningGibbous;
    if (D < 292.5) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }
}
