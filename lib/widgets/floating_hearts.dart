import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/gata_theme.dart';

/// A soft field of hearts drifting upward — used behind hero sections.
class FloatingHearts extends StatefulWidget {
  const FloatingHearts({super.key, this.count = 14});
  final int count;

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat();
  late final List<_Heart> _hearts;

  @override
  void initState() {
    super.initState();
    final r = Random(7);
    _hearts = List.generate(
      widget.count,
      (_) => _Heart(
        x: r.nextDouble(),
        size: 10 + r.nextDouble() * 22,
        speed: 0.4 + r.nextDouble() * 0.8,
        phase: r.nextDouble(),
        drift: (r.nextDouble() - 0.5) * 0.12,
        opacity: 0.10 + r.nextDouble() * 0.18,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _HeartPainter(_hearts, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Heart {
  final double x, size, speed, phase, drift, opacity;
  _Heart({
    required this.x,
    required this.size,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.opacity,
  });
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.hearts, this.t);
  final List<_Heart> hearts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final h in hearts) {
      final prog = (t * h.speed + h.phase) % 1.0;
      final y = size.height * (1.1 - prog * 1.2);
      final x = size.width * (h.x + sin(prog * 2 * pi) * h.drift);
      final paint = Paint()
        ..color = GataColors.rose.withValues(alpha: h.opacity * (1 - prog));
      _drawHeart(canvas, Offset(x, y), h.size, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path();
    final w = s, hh = s;
    path.moveTo(c.dx, c.dy + hh * 0.3);
    path.cubicTo(c.dx + w * 0.5, c.dy - hh * 0.3, c.dx + w * 0.9,
        c.dy + hh * 0.35, c.dx, c.dy + hh * 0.85);
    path.cubicTo(c.dx - w * 0.9, c.dy + hh * 0.35, c.dx - w * 0.5,
        c.dy - hh * 0.3, c.dx, c.dy + hh * 0.3);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.t != t;
}
