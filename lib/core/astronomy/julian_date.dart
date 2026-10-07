import 'astro_math.dart';

/// Julian Day Number utilities.
/// Algorithms from Jean Meeus, "Astronomical Algorithms", 2nd ed., Chapter 7.
class JulianDate {
  JulianDate._();

  /// J2000.0 epoch as Julian Day Number
  static const double j2000 = 2451545.0;

  // ---------------------------------------------------------------------------
  // DateTime → JD
  // ---------------------------------------------------------------------------

  /// Convert a [DateTime] (any timezone – converted internally to UTC) to
  /// its Julian Day Number (fractional days).
  static double fromDateTime(DateTime dt) {
    final utc = dt.toUtc();
    int y = utc.year;
    int m = utc.month;
    final d = utc.day +
        utc.hour / 24.0 +
        utc.minute / 1440.0 +
        utc.second / 86400.0 +
        utc.millisecond / 86400000.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = AstroMath.ifloor(y / 100.0);
    final b = 2 - a + AstroMath.ifloor(a / 4.0); // Gregorian correction

    return AstroMath.ifloor(365.25 * (y + 4716)) +
        AstroMath.ifloor(30.6001 * (m + 1)) +
        d +
        b -
        1524.5;
  }

  // ---------------------------------------------------------------------------
  // JD → DateTime
  // ---------------------------------------------------------------------------

  /// Convert a Julian Day Number back to a UTC [DateTime].
  static DateTime toDateTime(double jd) {
    final z = AstroMath.ifloor(jd + 0.5);
    final f = (jd + 0.5) - z;

    int a;
    if (z < 2299161) {
      a = z;
    } else {
      final alpha = AstroMath.ifloor((z - 1867216.25) / 36524.25);
      a = z + 1 + alpha - AstroMath.ifloor(alpha / 4.0);
    }

    final b = a + 1524;
    final c = AstroMath.ifloor((b - 122.1) / 365.25);
    final dd = AstroMath.ifloor(365.25 * c);
    final e = AstroMath.ifloor((b - dd) / 30.6001);

    final dayFrac =
        b - dd - AstroMath.ifloor(30.6001 * e).toDouble() + f;
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    final dayInt = dayFrac.floor();
    final hourFrac = (dayFrac - dayInt) * 24.0;
    final hourInt = hourFrac.floor();
    final minFrac = (hourFrac - hourInt) * 60.0;
    final minInt = minFrac.floor();
    final secFrac = (minFrac - minInt) * 60.0;
    final secInt = secFrac.round().clamp(0, 59);

    return DateTime.utc(year, month, dayInt, hourInt, minInt, secInt);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Julian centuries from J2000.0.
  static double julianCenturies(double jd) => (jd - j2000) / 36525.0;

  /// Julian millennia from J2000.0.
  static double julianMillennia(double jd) => (jd - j2000) / 365250.0;
}
