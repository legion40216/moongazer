import '../astronomy/moon_calculator.dart';
import '../astronomy/eclipse_calculator.dart';

/// All astronomical data computed for a single point in time.
/// Computed once per timer tick; passed to every widget via Riverpod.
class MoonState {
  // ─── Time ─────────────────────────────────────────────────────────────────
  final DateTime displayTime; // local or simulated
  final DateTime utcTime;

  // ─── Moon ─────────────────────────────────────────────────────────────────
  final double illumination; // 0.0 – 1.0
  final double ageInDays; // 0 – 29.53
  final MoonPhase phase;
  final double elongation; // 0 – 360°, used by moon painter
  final double moonDistanceKm;

  // ─── Sun ──────────────────────────────────────────────────────────────────
  final double sunDistanceKm;

  // ─── Phase events ─────────────────────────────────────────────────────────
  final DateTime lastNewMoon;
  final DateTime firstQuarter;
  final DateTime fullMoon;
  final DateTime lastQuarter;
  final DateTime nextNewMoon;

  // ─── Apsides ──────────────────────────────────────────────────────────────
  final DateTime nextPerigee;
  final DateTime nextApogee;

  // ─── Eclipses ─────────────────────────────────────────────────────────────
  final EclipseEvent? nextSolarEclipse;
  final EclipseEvent? nextLunarEclipse;

  // ─── App settings (carried here for convenience) ──────────────────────────
  final bool isNorthernHemisphere;
  final bool isSkippingTime;

  const MoonState({
    required this.displayTime,
    required this.utcTime,
    required this.illumination,
    required this.ageInDays,
    required this.phase,
    required this.elongation,
    required this.moonDistanceKm,
    required this.sunDistanceKm,
    required this.lastNewMoon,
    required this.firstQuarter,
    required this.fullMoon,
    required this.lastQuarter,
    required this.nextNewMoon,
    required this.nextPerigee,
    required this.nextApogee,
    required this.nextSolarEclipse,
    required this.nextLunarEclipse,
    required this.isNorthernHemisphere,
    required this.isSkippingTime,
  });

  MoonState copyWith({
    DateTime? displayTime,
    DateTime? utcTime,
    double? illumination,
    double? ageInDays,
    MoonPhase? phase,
    double? elongation,
    double? moonDistanceKm,
    double? sunDistanceKm,
    DateTime? lastNewMoon,
    DateTime? firstQuarter,
    DateTime? fullMoon,
    DateTime? lastQuarter,
    DateTime? nextNewMoon,
    DateTime? nextPerigee,
    DateTime? nextApogee,
    EclipseEvent? nextSolarEclipse,
    EclipseEvent? nextLunarEclipse,
    bool? isNorthernHemisphere,
    bool? isSkippingTime,
  }) =>
      MoonState(
        displayTime: displayTime ?? this.displayTime,
        utcTime: utcTime ?? this.utcTime,
        illumination: illumination ?? this.illumination,
        ageInDays: ageInDays ?? this.ageInDays,
        phase: phase ?? this.phase,
        elongation: elongation ?? this.elongation,
        moonDistanceKm: moonDistanceKm ?? this.moonDistanceKm,
        sunDistanceKm: sunDistanceKm ?? this.sunDistanceKm,
        lastNewMoon: lastNewMoon ?? this.lastNewMoon,
        firstQuarter: firstQuarter ?? this.firstQuarter,
        fullMoon: fullMoon ?? this.fullMoon,
        lastQuarter: lastQuarter ?? this.lastQuarter,
        nextNewMoon: nextNewMoon ?? this.nextNewMoon,
        nextPerigee: nextPerigee ?? this.nextPerigee,
        nextApogee: nextApogee ?? this.nextApogee,
        nextSolarEclipse: nextSolarEclipse ?? this.nextSolarEclipse,
        nextLunarEclipse: nextLunarEclipse ?? this.nextLunarEclipse,
        isNorthernHemisphere:
            isNorthernHemisphere ?? this.isNorthernHemisphere,
        isSkippingTime: isSkippingTime ?? this.isSkippingTime,
      );
}
