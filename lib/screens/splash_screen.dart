import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoAnim;
  late final AnimationController _glowAnim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _taglineFade;

  // Champagne gold palette
  static const _goldLight = Color(0xFFF5E6C8);
  static const _gold = Color(0xFFD4A852);
  static const _goldDark = Color(0xFFB8860B);
  static const _bgColor = Color(0xFF0D0A14);

  @override
  void initState() {
    super.initState();

    _glowAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: const Interval(0.35, 0.6, curve: Curves.easeIn)),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnim, curve: const Interval(0.55, 0.8, curve: Curves.easeIn)),
    );

    _logoAnim.forward();

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _glowAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoAnim, _glowAnim]),
        builder: (_, __) => Stack(
          children: [
            // Subtle radial glow behind monogram
            Center(
              child: Opacity(
                opacity: _logoFade.value * 0.3,
                child: Container(
                  width: 280 + _glowAnim.value * 40,
                  height: 280 + _glowAnim.value * 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _gold.withValues(alpha: 0.15 + _glowAnim.value * 0.08),
                        _bgColor,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decorative top ring
                  FadeTransition(
                    opacity: _logoFade,
                    child: _buildDecorativeRing(60),
                  ),
                  const SizedBox(height: 20),

                  // A+S Monogram
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: CustomPaint(
                        size: const Size(120, 120),
                        painter: _MonogramPainter(glow: _glowAnim.value),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Decorative bottom ring
                  FadeTransition(
                    opacity: _logoFade,
                    child: _buildDecorativeRing(40),
                  ),

                  const SizedBox(height: 32),

                  // GATA wordmark
                  FadeTransition(
                    opacity: _textFade,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_goldLight, _gold, _goldDark, _gold, _goldLight],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        'G A T A',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 14,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gold divider line
                  FadeTransition(
                    opacity: _textFade,
                    child: Container(
                      width: 160,
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, _gold, Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'PRIVATE  •  EXCLUSIVE',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: _gold.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
    );
  }
}

/// Draws an intertwined A+S monogram in champagne gold.
class _MonogramPainter extends CustomPainter {
  final double glow;
  _MonogramPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Gold gradient paint
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5E6C8), Color(0xFFD4A852), Color(0xFFB8860B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Outer circle
    final ringPaint = Paint()
      ..color = const Color(0xFFD4A852).withValues(alpha: 0.3 + glow * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(cx, cy), size.width / 2 - 4, ringPaint);

    // Inner decorative circle
    final innerRingPaint = Paint()
      ..color = const Color(0xFFD4A852).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawCircle(Offset(cx, cy), size.width / 2 - 12, innerRingPaint);

    // Draw 'A' letter
    final aPath = Path();
    final aLeft = cx - 22;
    final aRight = cx + 22;
    final aTop = cy - 28;
    final aBottom = cy + 28;
    // Left leg
    aPath.moveTo(aLeft, aBottom);
    aPath.lineTo(cx, aTop);
    // Right leg
    aPath.lineTo(aRight, aBottom);
    // Crossbar (flows into S)
    canvas.drawPath(aPath, goldPaint);

    // Crossbar as beginning of S curve
    final crossY = cy + 2;
    final sPath = Path();
    sPath.moveTo(aLeft + 8, crossY);
    // Upper curve of S
    sPath.cubicTo(
      cx + 18, crossY - 18,
      aRight + 4, crossY - 10,
      cx, cy - 8,
    );
    // Lower curve of S
    sPath.cubicTo(
      aLeft - 4, cy + 4,
      cx - 18, cy + 20,
      aRight - 8, crossY,
    );
    canvas.drawPath(sPath, goldPaint);

    // Glow dot at center
    final glowPaint = Paint()
      ..color = const Color(0xFFD4A852).withValues(alpha: 0.4 + glow * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(cx, cy - 2), 4, glowPaint);
  }

  @override
  bool shouldRepaint(_MonogramPainter old) => old.glow != glow;
}
