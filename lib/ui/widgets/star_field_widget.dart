import 'dart:math' as math;
import 'package:flutter/material.dart';

class _Star {
  final double x; // 0.0 – 1.0 (normalised)
  final double y;
  final double baseSize;
  final double twinkleOffset; // phase offset for animation
  final double twinkleSpeed;
  final Color color;

  const _Star({
    required this.x,
    required this.y,
    required this.baseSize,
    required this.twinkleOffset,
    required this.twinkleSpeed,
    required this.color,
  });
}

class StarFieldWidget extends StatefulWidget {
  final int numStars;
  final double height;

  const StarFieldWidget({
    super.key,
    this.numStars = 1000,
    required this.height,
  });

  @override
  State<StarFieldWidget> createState() => _StarFieldWidgetState();
}

class _StarFieldWidgetState extends State<StarFieldWidget>
    with SingleTickerProviderStateMixin {
  late List<_Star> _stars;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _stars = _generateStars(widget.numStars);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Star> _generateStars(int n) {
    final rng = math.Random(42); // fixed seed → deterministic layout
    final starColors = [
      Colors.white,
      const Color(0xFFCCDDFF), // blue-white
      const Color(0xFFFFEECC), // warm yellow
      const Color(0xFFFFCCCC), // faint red
    ];

    return List.generate(n, (_) {
      final size = rng.nextDouble() * 2.2 + 0.4;
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        baseSize: size,
        twinkleOffset: rng.nextDouble() * 2 * math.pi,
        twinkleSpeed: 0.5 + rng.nextDouble() * 2.0,
        color: starColors[rng.nextInt(starColors.length)],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _StarFieldPainter(
            stars: _stars,
            time: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double time; // 0 – 2π

  _StarFieldPainter({required this.stars, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = (math.sin(time * star.twinkleSpeed + star.twinkleOffset) + 1) / 2;
      final alpha = (0.3 + twinkle * 0.7).clamp(0.0, 1.0);
      final radius = star.baseSize * (0.7 + twinkle * 0.3);

      final paint = Paint()
        ..color = star.color.withOpacity(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.time != time;
}
