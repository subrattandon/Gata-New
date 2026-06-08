import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/haptic_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';

class TouchScreen extends StatefulWidget {
  const TouchScreen({super.key});

  @override
  State<TouchScreen> createState() => _TouchScreenState();
}

class _TouchScreenState extends State<TouchScreen> {
  static const _uuid = Uuid();
  final List<_TouchRipple> _ripples = [];
  StreamSubscription? _sub;
  bool _showHint = true;
  String? _partnerMessage;
  Timer? _msgTimer;

  @override
  void initState() {
    super.initState();
    _sub = FirestoreService.watchTouches().listen((touches) {
      for (final t in touches) {
        if (t.sender == Sender.her &&
            DateTime.now().difference(t.time).inSeconds < 8) {
          _onPartnerTouch(t);
          FirestoreService.deleteTouch(t.id);
        }
      }
    }, onError: (_) {});
  }

  void _onPartnerTouch(TouchEvent t) {
    Haptic.love();
    final app = context.read<AppState>();
    setState(() {
      _ripples.add(_TouchRipple(
        x: t.x,
        y: t.y,
        isPartner: true,
        key: UniqueKey(),
      ));
      _partnerMessage = '${app.userFor(Sender.her).name} felt you 💗';
    });
    _msgTimer?.cancel();
    _msgTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _partnerMessage = null);
    });
  }

  void _onMyTap(TapDownDetails details, Size size) {
    Haptic.heavy();
    setState(() => _showHint = false);
    final x = details.localPosition.dx / size.width;
    final y = details.localPosition.dy / size.height;

    setState(() {
      _ripples.add(_TouchRipple(
        x: x,
        y: y,
        isPartner: false,
        key: UniqueKey(),
      ));
    });

    final event = TouchEvent(
      id: _uuid.v4(),
      sender: Sender.me,
      x: x,
      y: y,
      time: DateTime.now(),
    );
    FirestoreService.sendTouch(event);
  }

  void _onRippleDone(_TouchRipple r) {
    if (mounted) setState(() => _ripples.remove(r));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Feel')),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onTapDown: (d) => _onMyTap(d, size),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  // Background particles
                  ..._ripples.map((r) => _HeartRippleWidget(
                        key: r.key,
                        ripple: r,
                        parentSize: size,
                        onDone: () => _onRippleDone(r),
                      )),

                  // Hint text
                  if (_showHint)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: GataColors.dusk,
                              boxShadow: [
                                BoxShadow(
                                  color: GataColors.rose.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('💕',
                                  style: TextStyle(fontSize: 36)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tap anywhere to\nsend your touch',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Your partner will feel it instantly',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: GataColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Partner message
                  if (_partnerMessage != null)
                    Positioned(
                      bottom: mq.padding.bottom + 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: GataColors.dusk,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: GataColors.rose.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            _partnerMessage!,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TouchRipple {
  final double x;
  final double y;
  final bool isPartner;
  final Key key;

  _TouchRipple({
    required this.x,
    required this.y,
    required this.isPartner,
    required this.key,
  });
}

class _HeartRippleWidget extends StatefulWidget {
  final _TouchRipple ripple;
  final Size parentSize;
  final VoidCallback onDone;

  const _HeartRippleWidget({
    super.key,
    required this.ripple,
    required this.parentSize,
    required this.onDone,
  });

  @override
  State<_HeartRippleWidget> createState() => _HeartRippleWidgetState();
}

class _HeartRippleWidgetState extends State<_HeartRippleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();

    final rng = Random();
    _particles = List.generate(8, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 30 + rng.nextDouble() * 60;
      return _Particle(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed,
        size: 12 + rng.nextDouble() * 16,
      );
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cx = widget.ripple.x * widget.parentSize.width;
    final cy = widget.ripple.y * widget.parentSize.height;
    final isPartner = widget.ripple.isPartner;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        final opacity = (1.0 - t).clamp(0.0, 1.0);

        return Stack(
          children: [
            // Central glow
            Positioned(
              left: cx - 50,
              top: cy - 50,
              child: Opacity(
                opacity: opacity * 0.6,
                child: Container(
                  width: 100 + t * 60,
                  height: 100 + t * 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isPartner
                          ? [
                              GataColors.lavender.withValues(alpha: 0.5),
                              GataColors.lavender.withValues(alpha: 0.0),
                            ]
                          : [
                              GataColors.rose.withValues(alpha: 0.5),
                              GataColors.rose.withValues(alpha: 0.0),
                            ],
                    ),
                  ),
                ),
              ),
            ),
            // Center heart
            Positioned(
              left: cx - 20,
              top: cy - 20,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: 0.5 + t * 0.8,
                  child: Text(
                    isPartner ? '💗' : '💕',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            // Particle hearts
            ..._particles.map((p) => Positioned(
                  left: cx + p.dx * t - p.size / 2,
                  top: cy + p.dy * t - p.size / 2,
                  child: Opacity(
                    opacity: (opacity * 0.8).clamp(0.0, 1.0),
                    child: CustomPaint(
                      size: Size(p.size, p.size),
                      painter: _MiniHeartPainter(
                        color: isPartner ? GataColors.lavender : GataColors.rose,
                      ),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _Particle {
  final double dx, dy, size;
  const _Particle({required this.dx, required this.dy, required this.size});
}

class _MiniHeartPainter extends CustomPainter {
  final Color color;
  _MiniHeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final w = size.width / 2;
    final h = size.height / 2;
    final path = Path();
    path.moveTo(c.dx, c.dy + h * 0.3);
    path.cubicTo(c.dx + w * 0.5, c.dy - h * 0.3, c.dx + w * 0.9,
        c.dy + h * 0.35, c.dx, c.dy + h * 0.85);
    path.cubicTo(c.dx - w * 0.9, c.dy + h * 0.35, c.dx - w * 0.5,
        c.dy - h * 0.3, c.dx, c.dy + h * 0.3);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MiniHeartPainter old) => old.color != color;
}
