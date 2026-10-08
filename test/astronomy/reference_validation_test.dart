// Validation against an independent ephemeris (Don Cross's Astronomy Engine).
// Expected values below were generated from that library, not typed from memory.

import 'package:flutter_test/flutter_test.dart';
import 'package:moongazer/core/astronomy/eclipse_calculator.dart';
import 'package:moongazer/core/astronomy/moon_calculator.dart';
import 'package:moongazer/core/astronomy/periapsis_calculator.dart';
import 'package:moongazer/core/astronomy/sun_calculator.dart';

void expectTimeNear(DateTime actual, DateTime expected, Duration tol,
    {String reason = ''}) {
  final diff = actual.difference(expected).abs();
  expect(diff <= tol, isTrue,
      reason: '${reason} expected ${expected.toIso8601String()} '
          '±${tol.inMinutes}min, got ${actual.toIso8601String()} '
          '(off by ${diff.inMinutes} min)');
}

class _Ref {
  final DateTime when;
  final EclipseType type;
  const _Ref(this.when, this.type);
}

void main() {
  group('Solar eclipses', () {
    final refs = <_Ref>[
      _Ref(DateTime.utc(2024, 4, 8, 18, 17), EclipseType.total),
      _Ref(DateTime.utc(2024, 10, 2, 18, 44), EclipseType.annular),
      _Ref(DateTime.utc(2025, 3, 29, 10, 47), EclipseType.partial),
      _Ref(DateTime.utc(2025, 9, 21, 19, 41), EclipseType.partial),
      _Ref(DateTime.utc(2026, 2, 17, 12, 11), EclipseType.annular),
      _Ref(DateTime.utc(2026, 8, 12, 17, 45), EclipseType.total),
      _Ref(DateTime.utc(2027, 2, 6, 15, 59), EclipseType.annular),
      _Ref(DateTime.utc(2027, 8, 2, 10, 6), EclipseType.total),
    ];
    for (final r in refs) {
      test('${r.type.label} solar eclipse ${r.when.toIso8601String()}', () {
        final found = EclipseCalculator.nextSolarEclipse(
            r.when.subtract(const Duration(days: 20)));
        expect(found, isNotNull);
        expect(found!.isSolar, isTrue);
        expectTimeNear(found.date, r.when, const Duration(minutes: 10));
        expect(found.type, equals(r.type));
      });
    }
    test('Next solar eclipse after 8 Oct 2026 is the Feb 2027 annular', () {
      final found = EclipseCalculator.nextSolarEclipse(DateTime.utc(2026, 10, 8));
      expect(found, isNotNull);
      expect(found!.type, equals(EclipseType.annular));
      expectTimeNear(
          found.date, DateTime.utc(2027, 2, 6, 15, 59), const Duration(minutes: 10));
    });
  });

  group('Lunar eclipses', () {
    final refs = <_Ref>[
      _Ref(DateTime.utc(2024, 3, 25, 7, 12), EclipseType.penumbral),
      _Ref(DateTime.utc(2024, 9, 18, 2, 44), EclipseType.partial),
      _Ref(DateTime.utc(2025, 3, 14, 6, 58), EclipseType.total),
      _Ref(DateTime.utc(2025, 9, 7, 18, 11), EclipseType.total),
      _Ref(DateTime.utc(2026, 3, 3, 11, 33), EclipseType.total),
      _Ref(DateTime.utc(2026, 8, 28, 4, 12), EclipseType.partial),
      _Ref(DateTime.utc(2027, 2, 20, 23, 12), EclipseType.penumbral),
      _Ref(DateTime.utc(2027, 7, 18, 16, 2), EclipseType.penumbral),
    ];
    for (final r in refs) {
      test('${r.type.label} lunar eclipse ${r.when.toIso8601String()}', () {
        final found = EclipseCalculator.nextLunarEclipse(
            r.when.subtract(const Duration(days: 20)));
        expect(found, isNotNull);
        expect(found!.isSolar, isFalse);
        expectTimeNear(found.date, r.when, const Duration(minutes: 10));
        expect(found.type, equals(r.type));
      });
    }
    test('Lunar eclipses report magnitudes; solar ones do not', () {
      final lunar = EclipseCalculator.nextLunarEclipse(DateTime.utc(2025, 3, 1))!;
      expect(lunar.umbralMagnitude, isNotNull);
      expect(lunar.umbralMagnitude!, greaterThan(1.0));
      final solar = EclipseCalculator.nextSolarEclipse(DateTime.utc(2025, 3, 1))!;
      expect(solar.umbralMagnitude, isNull);
    });
    test('Search never returns an eclipse in the past', () {
      final now = DateTime.utc(2026, 3, 3, 12, 0);
      final found = EclipseCalculator.nextLunarEclipse(now)!;
      expect(found.date.isAfter(now), isTrue);
    });
  });

  group('Moon distance (reference ±100 km)', () {
    final cases = <List<Object>>[
      [DateTime.utc(2024, 1, 1, 0), 404656.0],
      [DateTime.utc(2025, 6, 15, 12), 386119.0],
      [DateTime.utc(2026, 10, 8, 0), 378564.0],
      [DateTime.utc(2027, 3, 3, 6), 405206.0],
    ];
    for (final c in cases) {
      test('Moon distance at ${c[0]}', () {
        final km = MoonCalculator.calculate(c[0] as DateTime).distanceKm;
        expect((km - (c[1] as double)).abs(), lessThan(100),
            reason: 'got $km, expected ${c[1]}');
      });
    }
  });

  group('Sun distance (reference ±20,000 km)', () {
    test('Perihelion-ish, 3 Jan 2026', () {
      final km = SunCalculator.distanceKm(DateTime.utc(2026, 1, 3));
      expect((km - 147100038).abs(), lessThan(20000));
    });
    test('Aphelion-ish, 6 Jul 2026', () {
      final km = SunCalculator.distanceKm(DateTime.utc(2026, 7, 6));
      expect((km - 152087879).abs(), lessThan(20000));
    });
  });

  group('Perigee and apogee after 8 Oct 2026', () {
    final from = DateTime.utc(2026, 10, 8);
    test('Next apogee 16 Oct 2026 22:54 UTC (±10 min)', () {
      expectTimeNear(PeriapsisCalculator.nextApogee(from),
          DateTime.utc(2026, 10, 16, 22, 54), const Duration(minutes: 10));
    });
    test('Next perigee 28 Oct 2026 18:04 UTC (±45 min)', () {
      expectTimeNear(PeriapsisCalculator.nextPerigee(from),
          DateTime.utc(2026, 10, 28, 18, 4), const Duration(minutes: 45));
    });
    test('Following apogee 13 Nov 2026 17:50 UTC (±10 min)', () {
      expectTimeNear(
          PeriapsisCalculator.nextApogee(DateTime.utc(2026, 10, 17)),
          DateTime.utc(2026, 11, 13, 17, 50),
          const Duration(minutes: 10));
    });
    test('Following perigee 25 Nov 2026 21:02 UTC (±45 min)', () {
      expectTimeNear(
          PeriapsisCalculator.nextPerigee(DateTime.utc(2026, 10, 29)),
          DateTime.utc(2026, 11, 25, 21, 2),
          const Duration(minutes: 45));
    });
  });

  group('Current lunation on 8 Oct 2026', () {
    final l = MoonCalculator.lunation(DateTime.utc(2026, 10, 8));
    const tol = Duration(minutes: 5);
    test('Last new moon 11 Sep 2026 03:27', () =>
        expectTimeNear(l.lastNewMoon, DateTime.utc(2026, 9, 11, 3, 27), tol));
    test('First quarter 18 Sep 2026 20:44', () =>
        expectTimeNear(l.firstQuarter, DateTime.utc(2026, 9, 18, 20, 44), tol));
    test('Full moon 26 Sep 2026 16:49', () =>
        expectTimeNear(l.fullMoon, DateTime.utc(2026, 9, 26, 16, 49), tol));
    test('Last quarter 3 Oct 2026 13:25', () =>
        expectTimeNear(l.lastQuarter, DateTime.utc(2026, 10, 3, 13, 25), tol));
    test('Next new moon 10 Oct 2026 15:50', () =>
        expectTimeNear(l.nextNewMoon, DateTime.utc(2026, 10, 10, 15, 50), tol));
    test('Events are in chronological order for 500 consecutive days', () {
      for (int i = 0; i < 500; i++) {
        final dt = DateTime.utc(2025, 1, 1).add(Duration(days: i, hours: 5));
        final e = MoonCalculator.lunation(dt);
        expect(e.lastNewMoon.isBefore(e.firstQuarter), isTrue, reason: '$dt');
        expect(e.firstQuarter.isBefore(e.fullMoon), isTrue, reason: '$dt');
        expect(e.fullMoon.isBefore(e.lastQuarter), isTrue, reason: '$dt');
        expect(e.lastQuarter.isBefore(e.nextNewMoon), isTrue, reason: '$dt');
        expect(!e.lastNewMoon.isAfter(dt), isTrue,
            reason: 'last new moon must not be in the future at $dt');
        expect(e.nextNewMoon.isAfter(dt), isTrue,
            reason: 'next new moon must be in the future at $dt');
      }
    });
  });
}
