import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/haptic_service.dart';
import '../theme/gata_theme.dart';
import '../widgets/floating_hearts.dart';

class ReactionOverlay extends StatefulWidget {
  final QuickReaction reaction;
  final String partnerName;
  final VoidCallback onDismiss;

  const ReactionOverlay({
    super.key,
    required this.reaction,
    required this.partnerName,
    required this.onDismiss,
  });

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    Haptic.love();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _anim.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _anim.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.reaction.type;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            color: Colors.black.withValues(alpha: 0.85),
            child: Stack(
              children: [
                const FloatingHearts(count: 20),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glow behind emoji
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: GataColors.rose.withValues(alpha: 0.4),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ScaleTransition(
                            scale: _scale,
                            child: Text(
                              type.emoji,
                              style: const TextStyle(fontSize: 100),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ScaleTransition(
                        scale: _scale,
                        child: Text(
                          '${widget.partnerName} sent you a ${type.label}!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _fade,
                        child: Text(
                          'Tap to dismiss',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: GataColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
