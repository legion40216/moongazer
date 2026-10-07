import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';

/// Renders the moon with a physically accurate phase shadow.
///
/// Algorithm:
///   The illuminated crescent/gibbous is produced by drawing a dark
///   shadow path that consists of one semicircle arc (the dark half of
///   the disk) plus a terminator ellipse arc that connects top to bottom.
///   cos(elongation) gives the signed x-scale of that ellipse:
///     +1  → new moon  (terminator on far side  → all dark)
///     0   → quarter   (terminator is vertical   → half dark)
///     −1  → full moon (terminator on near side  → all light)
///   For the southern hemisphere the elongation is mirrored (360° − e).
class MoonCanvasWidget extends StatelessWidget {
  final double illumination; // 0.0 – 1.0
  final double elongation; // 0° – 360° (mean elongation, 0=new, 180=full)
  final bool isNorthernHemisphere;
  final double size;

  const MoonCanvasWidget({
    super.key,
    required this.illumination,
    required this.elongation,
    required this.isNorthernHemisphere,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoonPainter(
          illumination: illumination,
          elongation: elongation,
          isNorthernHemisphere: isNorthernHemisphere,
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double illumination;
  final double elongation;
  final bool isNorthernHemisphere;

  const _MoonPainter({
    required this.illumination,
    required this.elongation,
    required this.isNorthernHemisphere,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - 2;
    final center = Offset(size.width / 2, size.height / 2);

    // ── 1. Outer glow ──────────────────────────────────────────────────────
    if (illumination > 0.05) {
      final glowAlpha = (illumination * 0.18).clamp(0.0, 0.18);
      canvas.drawCircle(
        center,
        r * 1.35,
        Paint()
          ..color = AppColors.moonGlow.withOpacity(glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }

    // ── 2. Moon disk surface ───────────────────────────────────────────────
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Base lit colour
    canvas.drawCircle(center, r, Paint()..color = AppColors.moonSurface);

    // Simple surface texture: a handful of subtle grey circles as craters
    _drawCraters(canvas, center, r);

    // ── 3. Phase shadow ────────────────────────────────────────────────────
    _drawShadow(canvas, center, r);

    canvas.restore();

    // ── 4. Rim ─────────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // ── Shadow path ──────────────────────────────────────────────────────────

  void _drawShadow(Canvas canvas, Offset center, double r) {
    // Mirror elongation for southern hemisphere
    final e = isNorthernHemisphere ? elongation : (360.0 - elongation);

    final shadowPaint = Paint()
      ..color = AppColors.moonShadow
      ..style = PaintingStyle.fill;

    // New moon → fully dark
    if (illumination < 0.01) {
      canvas.drawCircle(center, r, shadowPaint);
      return;
    }
    // Full moon → no shadow
    if (illumination > 0.99) return;

    final isWaxing = e < 180.0;
    // cos(e) ranges: new(0°)→1, quarter(90°)→0, full(180°)→-1
    final cosE = math.cos(e * math.pi / 180.0);

    final path = Path();
    const steps = 64;

    if (isWaxing) {
      // Shadow on the LEFT half
      // Step 1: left-semicircle arc from top → bottom (counterclockwise in screen coords)
      for (int i = 0; i <= steps; i++) {
        final t = -math.pi / 2 - math.pi * i / steps; // -π/2 → -3π/2
        final x = center.dx + r * math.cos(t);
        final y = center.dy + r * math.sin(t);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      // Step 2: terminator ellipse from bottom → top
      // x = center.dx + r * cosE * cos(t),  y = center.dy + r * sin(t)
      // t from +π/2 (bottom) → -π/2 (top)
      for (int i = 0; i <= steps; i++) {
        final t = math.pi / 2 - math.pi * i / steps;
        final x = center.dx + r * cosE * math.cos(t);
        final y = center.dy + r * math.sin(t);
        path.lineTo(x, y);
      }
    } else {
      // Shadow on the RIGHT half
      for (int i = 0; i <= steps; i++) {
        final t = -math.pi / 2 + math.pi * i / steps; // -π/2 → +π/2
        final x = center.dx + r * math.cos(t);
        final y = center.dy + r * math.sin(t);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      for (int i = 0; i <= steps; i++) {
        final t = math.pi / 2 - math.pi * i / steps;
        final x = center.dx + r * cosE * math.cos(t);
        final y = center.dy + r * math.sin(t);
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, shadowPaint);
  }

  // ── Crater texture ────────────────────────────────────────────────────────

  void _drawCraters(Canvas canvas, Offset center, double r) {
    final craterPaint = Paint()
      ..color = const Color(0xFFD0C8B0).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = const Color(0xFFC0B8A0).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final craters = [
      // (dx, dy, radius) all in fractions of moon radius r
      _Crater(-0.25, -0.30, 0.11),
      _Crater(0.15, -0.10, 0.09),
      _Crater(-0.05, 0.30, 0.07),
      _Crater(0.30, 0.25, 0.06),
      _Crater(-0.40, 0.10, 0.05),
      _Crater(0.10, -0.38, 0.06),
      _Crater(-0.15, 0.05, 0.04),
      _Crater(0.35, -0.20, 0.04),
    ];

    for (final c in craters) {
      final pos = Offset(center.dx + c.dx * r, center.dy + c.dy * r);
      canvas.drawCircle(pos, c.radius * r, craterPaint);
      canvas.drawCircle(pos, c.radius * r, rimPaint);
    }
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.illumination != illumination ||
      old.elongation != elongation ||
      old.isNorthernHemisphere != isNorthernHemisphere;
}

class _Crater {
  final double dx, dy, radius;
  const _Crater(this.dx, this.dy, this.radius);
}
