import 'astro_math.dart';
import 'julian_date.dart';
import 'moon_calculator.dart';

// ---------------------------------------------------------------------------
// Eclipse types (mirrors original EXE strings)
// ---------------------------------------------------------------------------

enum EclipseType { none, partial, total, annular, penumbral }

extension EclipseTypeLabel on EclipseType {
  String get label {
    switch (this) {
      case EclipseType.none: return 'None';
      case EclipseType.partial: return 'Partial';
      case EclipseType.total: return 'Total';
      case EclipseType.annular: return 'Annular';
      case EclipseType.penumbral: return 'Penumbral';
    }
  }
}

class EclipseEvent {
  final DateTime date;
  final bool isSolar;
  final EclipseType type;

  const EclipseEvent({
    required this.date,
    required this.isSolar,
    required this.type,
  });

  String get title => isSolar ? 'Solar Eclipse' : 'Lunar Eclipse';
  String get typeLabel => type.label;
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

/// Eclipse prediction.
/// Algorithm: Meeus "Astronomical Algorithms" 2nd ed., Chapter 54.
///
/// A solar eclipse is possible near new moon when F (Moon's argument of
/// latitude) is within ~13.9° of 0° or 180°.
/// A lunar eclipse is possible near full moon when F is within ~21.0° of
/// 0° or 180°.
class EclipseCalculator {
  EclipseCalculator._();

  /// Next solar eclipse (any type) after [dt].
  static EclipseEvent? nextSolarEclipse(DateTime dt) {
    return _findEclipse(dt, solar: true);
  }

  /// Next lunar eclipse (any type) after [dt].
  static EclipseEvent? nextLunarEclipse(DateTime dt) {
    return _findEclipse(dt, solar: false);
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  static EclipseEvent? _findEclipse(DateTime dt, {required bool solar}) {
    final jd = JulianDate.fromDateTime(dt);
    final T0 = JulianDate.julianCenturies(jd);
    double kBase = (T0 * 1236.85).floorToDouble();

    // Search forward up to ~36 new/full moons (≈3 years) to guarantee a hit
    for (int i = 0; i < 36; i++) {
      final k = kBase + i;
      final T = k / 1236.85;

      // Moon's argument of latitude at this phase (Meeus 54.1)
      final F = AstroMath.normalize360(
          160.7108 + 390.67050274 * k - 0.0016341 * T * T);

      final fMod = F % 180.0;
      // Distance from node (0° or 180°)
      final fNode = fMod > 90.0 ? 180.0 - fMod : fMod;

      final double limit = solar ? 13.9 : 21.0;
      if (fNode < limit) {
        final PhaseEventType phaseType =
            solar ? PhaseEventType.newMoon : PhaseEventType.fullMoon;
        final jde = MoonCalculator.nextPhaseEvent(
          JulianDate.toDateTime(jd - 1),
          phaseType,
        );
        final jdeVal = JulianDate.fromDateTime(jde);
        // Make sure this JDE is actually after dt and matches the approximate k
        if (jdeVal > jd + 0.1) {
          final type = solar
              ? _classifySolar(fNode)
              : _classifyLunar(fNode);
          return EclipseEvent(
            date: jde,
            isSolar: solar,
            type: type,
          );
        }
      }
    }
    return null;
  }

  static EclipseType _classifySolar(double fNode) {
    if (fNode < 4.0) return EclipseType.total;   // could be annular – simplified
    if (fNode < 9.0) return EclipseType.annular;
    return EclipseType.partial;
  }

  static EclipseType _classifyLunar(double fNode) {
    if (fNode < 4.0) return EclipseType.total;
    if (fNode < 10.0) return EclipseType.partial;
    return EclipseType.penumbral;
  }
}
