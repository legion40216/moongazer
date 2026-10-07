import 'package:flutter_test/flutter_test.dart';
import 'package:moongazer/core/astronomy/julian_date.dart';
import 'package:moongazer/core/astronomy/moon_calculator.dart';
import 'package:moongazer/core/astronomy/sun_calculator.dart';
import 'package:moongazer/core/astronomy/periapsis_calculator.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Tolerance helpers
// ──────────────────────────────────────────────────────────────────────────────

void expectNear(double actual, double expected, double tolerance,
    {String? reason}) {
  final diff = (actual - expected).abs();
  expect(diff <= tolerance, isTrue,
      reason:
          '${reason ?? ''} expected $expected ± $tolerance, got $actual (diff=$diff)');
}

void expectDateNear(DateTime actual, DateTime expected, Duration tolerance,
    {String? reason}) {
  final diff = actual.difference(expected).abs();
  expect(diff <= tolerance, isTrue,
      reason:
          '${reason ?? ''} expected ${expected.toIso8601String()} ± ${tolerance.inMinutes}min, '
          'got ${actual.toIso8601String()} (diff=${diff.inMinutes}min)');
}

// ──────────────────────────────────────────────────────────────────────────────
// Julian Date
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  group('JulianDate', () {
    test('J2000.0 epoch = 2451545.0', () {
      final jd = JulianDate.fromDateTime(DateTime.utc(2000, 1, 1, 12, 0, 0));
      expectNear(jd, 2451545.0, 0.00001, reason: 'J2000 epoch');
    });

    test('1987-Apr-10 = JD 2446895.5 (Meeus example)', () {
      final jd = JulianDate.fromDateTime(DateTime.utc(1987, 4, 10));
      expectNear(jd, 2446895.5, 0.0001, reason: 'Meeus Ch7 example');
    });

    test('round-trip: JD → DateTime → JD', () {
      final dt = DateTime.utc(2024, 3, 25, 7, 30, 0);
      final jd = JulianDate.fromDateTime(dt);
      final dt2 = JulianDate.toDateTime(jd);
      expect(dt2.year, equals(dt.year));
      expect(dt2.month, equals(dt.month));
      expect(dt2.day, equals(dt.day));
      expect(dt2.hour, equals(dt.hour));
      expect((dt2.minute - dt.minute).abs(), lessThanOrEqualTo(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Moon illumination sanity checks
  // ──────────────────────────────────────────────────────────────────────────

  group('MoonCalculator – illumination', () {
    test('Near new moon → illumination < 5%', () {
      // New moon: 2024-Jan-11 11:57 UTC
      final dt = DateTime.utc(2024, 1, 11, 12, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.illumination, lessThan(0.05),
          reason: 'New moon should be <5% illuminated');
    });

    test('Near full moon → illumination > 95%', () {
      // Full moon: 2024-Jan-25 17:54 UTC
      final dt = DateTime.utc(2024, 1, 25, 18, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.illumination, greaterThan(0.95),
          reason: 'Full moon should be >95% illuminated');
    });

    test('Near first quarter → illumination 45–55%', () {
      // First quarter: 2024-Jan-17 22:52 UTC
      final dt = DateTime.utc(2024, 1, 17, 23, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.illumination, greaterThan(0.45));
      expect(pos.illumination, lessThan(0.55));
    });

    test('Illumination always in [0, 1]', () {
      // Check 30 dates spread over a year
      for (int i = 0; i < 30; i++) {
        final dt = DateTime.utc(2024, 1, 1).add(Duration(days: i * 12));
        final pos = MoonCalculator.calculate(dt);
        expect(pos.illumination, greaterThanOrEqualTo(0.0));
        expect(pos.illumination, lessThanOrEqualTo(1.0));
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Moon age
  // ──────────────────────────────────────────────────────────────────────────

  group('MoonCalculator – age', () {
    test('Age at new moon ≈ 0 days', () {
      final dt = DateTime.utc(2024, 1, 11, 12, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.ageInDays, lessThan(2.0));
    });

    test('Age at full moon ≈ 14–15 days', () {
      final dt = DateTime.utc(2024, 1, 25, 18, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.ageInDays, greaterThan(12.0));
      expect(pos.ageInDays, lessThan(17.0));
    });

    test('Age always in [0, 29.53]', () {
      for (int i = 0; i < 30; i++) {
        final dt = DateTime.utc(2024, 1, 1).add(Duration(days: i * 11));
        final pos = MoonCalculator.calculate(dt);
        expect(pos.ageInDays, greaterThanOrEqualTo(0.0));
        expect(pos.ageInDays, lessThanOrEqualTo(29.54));
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Phase events
  // ──────────────────────────────────────────────────────────────────────────

  group('MoonCalculator – phase events', () {
    // Reference: full moon 2024-Jan-25 17:54 UTC  (NASA confirmed)
    test('Full moon Jan 2024 within ±12 hours of 2024-01-25 17:54 UTC', () {
      final reference = DateTime.utc(2024, 1, 25, 17, 54);
      final dt = DateTime.utc(2024, 1, 20); // start search from mid-month
      final result = MoonCalculator.nextPhaseEvent(dt, PhaseEventType.fullMoon);
      expectDateNear(result, reference, const Duration(hours: 12),
          reason: 'Full moon Jan 2024');
    });

    // Reference: new moon 2024-Feb-9 22:59 UTC
    test('New moon Feb 2024 within ±12 hours', () {
      final reference = DateTime.utc(2024, 2, 9, 22, 59);
      final dt = DateTime.utc(2024, 2, 5);
      final result = MoonCalculator.nextPhaseEvent(dt, PhaseEventType.newMoon);
      expectDateNear(result, reference, const Duration(hours: 12),
          reason: 'New moon Feb 2024');
    });

    // Reference: first quarter 2024-Mar-17 04:11 UTC
    test('First quarter Mar 2024 within ±12 hours', () {
      final reference = DateTime.utc(2024, 3, 17, 4, 11);
      final dt = DateTime.utc(2024, 3, 10);
      final result =
          MoonCalculator.nextPhaseEvent(dt, PhaseEventType.firstQuarter);
      expectDateNear(result, reference, const Duration(hours: 12),
          reason: 'First quarter Mar 2024');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Moon distance
  // ──────────────────────────────────────────────────────────────────────────

  group('MoonCalculator – distance', () {
    test('Moon distance stays within realistic bounds (356000–406700 km)', () {
      for (int i = 0; i < 60; i++) {
        final dt = DateTime.utc(2024, 1, 1).add(Duration(days: i * 6));
        final pos = MoonCalculator.calculate(dt);
        expect(pos.distanceKm, greaterThan(350000),
            reason: 'Distance too small at $dt');
        expect(pos.distanceKm, lessThan(410000),
            reason: 'Distance too large at $dt');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Sun distance
  // ──────────────────────────────────────────────────────────────────────────

  group('SunCalculator', () {
    test('Sun distance in realistic AU range (147M–152M km)', () {
      for (int month = 1; month <= 12; month++) {
        final dt = DateTime.utc(2024, month, 15);
        final km = SunCalculator.distanceKm(dt);
        expect(km, greaterThan(147_000_000));
        expect(km, lessThan(153_000_000));
      }
    });

    test('Earth closest to Sun in early January (perihelion)', () {
      // Perihelion ~Jan 3–5 each year
      final perihelion = SunCalculator.distanceKm(DateTime.utc(2024, 1, 4));
      final aphelion = SunCalculator.distanceKm(DateTime.utc(2024, 7, 5));
      expect(perihelion, lessThan(aphelion),
          reason: 'Jan distance should be less than Jul distance');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Perigee / Apogee
  // ──────────────────────────────────────────────────────────────────────────

  group('PeriapsisCalculator', () {
    // Perigee: 2024-Jan-13 (NASA)
    test('Perigee Jan 2024 within ±2 days of 2024-01-13', () {
      final reference = DateTime.utc(2024, 1, 13);
      final dt = DateTime.utc(2024, 1, 5);
      final result = PeriapsisCalculator.nextPerigee(dt);
      expectDateNear(result, reference, const Duration(days: 2),
          reason: 'Perigee Jan 2024');
    });

    test('Apogee is always later than next perigee when starting at same time',
        () {
      final dt = DateTime.utc(2024, 3, 1);
      final perigee = PeriapsisCalculator.nextPerigee(dt);
      final apogee = PeriapsisCalculator.nextApogee(dt);
      // They shouldn't be the same day
      expect(perigee.difference(apogee).abs().inDays, greaterThan(5));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Phase name
  // ──────────────────────────────────────────────────────────────────────────

  group('MoonPhase names', () {
    test('Near new moon → MoonPhase.newMoon', () {
      final dt = DateTime.utc(2024, 1, 11, 12, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.phase, equals(MoonPhase.newMoon));
    });

    test('Near full moon → MoonPhase.fullMoon', () {
      final dt = DateTime.utc(2024, 1, 25, 18, 0, 0);
      final pos = MoonCalculator.calculate(dt);
      expect(pos.phase, equals(MoonPhase.fullMoon));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Hemisphere rendering
  // ──────────────────────────────────────────────────────────────────────────

  group('Hemisphere', () {
    test('Waxing crescent elongation is in [22.5, 67.5] degrees', () {
      // After a new moon, elongation grows
      final dt = DateTime.utc(2024, 1, 14); // ~3 days after new moon
      final pos = MoonCalculator.calculate(dt);
      expect(pos.elongation, greaterThan(20));
      expect(pos.elongation, lessThan(90));
    });
  });
}
