import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/haptic_service.dart';
import '../state/app_state.dart';
import '../theme/gata_theme.dart';

// ─────────────────────────────────────────────────────────────
// Demo card
// ─────────────────────────────────────────────────────────────

class DemoFlipCard extends StatelessWidget {
  const DemoFlipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final post = Post(
      id: '__demo__',
      caption: 'Hold the heart to send love 💕\nFlip to leave a compliment.',
      emoji: '🐱',
      author: Sender.her,
      time: DateTime.now(),
    );
    return FeedPostCard(
      key: const ValueKey('demo'),
      post: post,
      author: const AppUser(name: 'Her', emoji: '🌷'),
      onLove: (_, __) {},
      isDemo: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Flip card
// ─────────────────────────────────────────────────────────────

class FeedPostCard extends StatefulWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.author,
    required this.onLove,
    this.onCompliment,
    this.onProfileTap,
    this.isDemo = false,
  });

  final Post post;
  final AppUser author;
  final void Function(String postId, double intensity) onLove;
  final ValueChanged<String>? onCompliment;
  final VoidCallback? onProfileTap;
  final bool isDemo;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard>
    with TickerProviderStateMixin {
  // ── Flip ─────────────────────────────────────────────────
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  // ── Card entry ───────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entrySlide;

  // ── Heart burst ──────────────────────────────────────────
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;
  late final Animation<double> _heartOpacity;
  late final Animation<double> _heartY;

  // ── Love message ─────────────────────────────────────────
  late final AnimationController _msgCtrl;
  late final Animation<double> _msgOpacity;
  late final Animation<double> _msgY;

  // ── Hold-to-love ─────────────────────────────────────────
  late final AnimationController _holdCtrl;
  double _holdIntensity = 0.0;
  bool _isHolding = false;

  // ── Glow ─────────────────────────────────────────────────
  late final AnimationController _glowCtrl;

  String? _sentCompliment;

  @override
  void initState() {
    super.initState();

    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _flipAnim =
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic);

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entryOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entrySlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.6), weight: 22),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.1), weight: 18),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 32),
    ]).animate(_heartCtrl);
    _heartY = Tween(begin: 0.0, end: -90.0)
        .animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

    _msgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _msgOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_msgCtrl);
    _msgY = Tween(begin: 20.0, end: -20.0)
        .animate(CurvedAnimation(parent: _msgCtrl, curve: Curves.easeOut));

    _holdCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..addListener(() {
        setState(() => _holdIntensity = _holdCtrl.value);
        // Haptic pulses at 25%, 50%, 75%, 100%
        final v = _holdCtrl.value;
        if ((v - 0.25).abs() < 0.01 ||
            (v - 0.50).abs() < 0.01 ||
            (v - 0.75).abs() < 0.01 ||
            (v - 1.0).abs() < 0.01) {
          Haptic.light();
        }
      });

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _entryCtrl.dispose();
    _heartCtrl.dispose();
    _msgCtrl.dispose();
    _holdCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    Haptic.medium();
    if (_flipCtrl.isCompleted) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
  }

  void _startHoldLove() {
    if (widget.isDemo) return;
    _isHolding = true;
    _holdCtrl.forward(from: 0);
    Haptic.soft();
  }

  void _endHoldLove() {
    if (!_isHolding) return;
    _isHolding = false;
    _holdCtrl.stop();
    final intensity = _holdIntensity.clamp(0.1, 1.0);
    widget.onLove(widget.post.id, intensity);
    _heartCtrl.forward(from: 0);
    _msgCtrl.forward(from: 0);
    Haptic.love();
    setState(() => _holdIntensity = 0.0);
  }

  void _doubleTapLove() {
    Haptic.love();
    widget.onLove(widget.post.id, 1.0);
    _heartCtrl.forward(from: 0);
    _msgCtrl.forward(from: 0);
  }

  void _sendCompliment(String text) {
    Haptic.success();
    setState(() => _sentCompliment = text);
    widget.onCompliment?.call(text);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _sentCompliment = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryOpacity,
      child: SlideTransition(
        position: _entrySlide,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 32,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (_, _) {
                final t = _flipAnim.value;
                final angle = t * math.pi;
                final isBack = t > 0.5;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(isBack ? angle - math.pi : angle),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: isBack ? _buildBack() : _buildFront(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── FRONT FACE ───────────────────────────────────────────

  Widget _buildFront() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed image / demo gradient
        _frontImage(),

        // Private post blur overlay
        if (widget.post.isPrivate) _privateOverlay(),

        // Subtle top gradient for readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000)],
              ),
            ),
          ),
        ),

        // Private badge
        if (widget.post.isPrivate)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: GataColors.rose.withValues(alpha: 0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 12, color: GataColors.rose),
                  const SizedBox(width: 4),
                  Text('Private',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GataColors.rose,
                      )),
                ],
              ),
            ),
          ),

        // Bottom strip
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _frontStrip(),
        ),

        // Heart burst
        _heartBurst(),

        // Love message
        _loveMessage(),

        // Hold glow overlay
        if (_isHolding) _holdGlow(),
      ],
    );
  }

  Widget _privateOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  GataColors.rose.withValues(alpha: 0.08),
                  GataColors.lavender.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                          color: GataColors.rose.withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: GataColors.rose, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Private moment',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only you two can see this',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _holdGlow() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (_, _) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: GataColors.rose
                    .withValues(alpha: _holdIntensity * 0.6 * (0.5 + _glowCtrl.value * 0.5)),
                width: 2 + _holdIntensity * 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: GataColors.rose.withValues(alpha: _holdIntensity * 0.3),
                  blurRadius: 20 + _holdIntensity * 30,
                  spreadRadius: _holdIntensity * 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _frontImage() {
    if (widget.isDemo) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 0.88, 1.0],
            colors: [
              Color(0xFFFFE4C4),
              Color(0xFFFFE7DE),
              Color(0xFFFFD3C3),
              Color(0xFFFF7F50),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐱', style: TextStyle(fontSize: 100)),
              const SizedBox(height: 16),
              Text(
                'Your moments\nlive here',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF7A3A20),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hold heart to love • Flip to compliment',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xAA7A3A20),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _doubleTapLove,
      child: Hero(
        tag: 'post_${widget.post.id}',
        child: _resolveImage(),
      ),
    );
  }

  Widget _resolveImage() {
    if (!widget.post.hasPhoto) {
      return Container(
        decoration: const BoxDecoration(gradient: GataColors.lavenderGlow),
        child: Center(
          child:
              Text(widget.post.emoji, style: const TextStyle(fontSize: 96)),
        ),
      );
    }
    final path = widget.post.imagePath!;
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        placeholder: (_, _) => const _SkeletonBox(),
        errorWidget: (_, _, _) => _brokenImage(),
      );
    }
    final file = File(path);
    if (!file.existsSync()) return _brokenImage();
    return Image.file(
      file,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => _brokenImage(),
    );
  }

  Widget _brokenImage() => Container(
        color: GataColors.surfaceElevated,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded,
                  color: GataColors.textMuted, size: 48),
              const SizedBox(height: 8),
              Text('Photo unavailable',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GataColors.textMuted,
                  )),
            ],
          ),
        ),
      );

  Widget _frontStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xBB000000)],
        ),
      ),
      child: Row(
        children: [
          // Author pill
          GestureDetector(
            onTap: () {
              Haptic.select();
              widget.onProfileTap?.call();
            },
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [GataColors.rose, GataColors.lavender],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GataColors.rose.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(widget.author.emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.author.name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0x88000000), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Hold-to-love heart button
          GestureDetector(
            onLongPressStart: (_) => _startHoldLove(),
            onLongPressEnd: (_) => _endHoldLove(),
            onTap: () {
              if (!widget.isDemo) {
                Haptic.love();
                widget.onLove(widget.post.id, 0.5);
                _heartCtrl.forward(from: 0);
                _msgCtrl.forward(from: 0);
              }
            },
            child: AnimatedBuilder(
              animation: _holdCtrl,
              builder: (_, _) {
                final scale = 1.0 + _holdIntensity * 0.8;
                return Transform.scale(
                  scale: _isHolding ? scale : 1.0,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.post.loved
                          ? GataColors.rose.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.12),
                      boxShadow: _isHolding
                          ? [
                              BoxShadow(
                                color: GataColors.rose
                                    .withValues(alpha: _holdIntensity * 0.6),
                                blurRadius: 16 + _holdIntensity * 16,
                                spreadRadius: _holdIntensity * 4,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      widget.post.loved || _isHolding
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: widget.post.loved || _isHolding
                          ? GataColors.rose
                          : Colors.white,
                      size: 22,
                      shadows: const [
                        Shadow(color: Color(0x88000000), blurRadius: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // Compliment button
          GestureDetector(
            onTap: () {
              Haptic.select();
              _showComplimentSheet(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 19, color: Colors.white,
                  shadows: [Shadow(color: Color(0x88000000), blurRadius: 4)]),
            ),
          ),

          const SizedBox(width: 10),

          // Flip button
          GestureDetector(
            onTap: _flip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flip_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('Story',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComplimentSheet(BuildContext context) {
    if (widget.isDemo) return;
    const pills = [
      'You look gorgeous 💕',
      'Love this! 🌸',
      'So cute! 🥺',
      'Miss you 💌',
      'Beautiful ✨',
      'Made my day 🥰',
    ];
    final custom = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: GataColors.surfaceFloat,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: GataColors.rose.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Leave a compliment 💌',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: GataColors.textPrimary,
                  )),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pills.map((p) {
                  return GestureDetector(
                    onTap: () {
                      _sendCompliment(p);
                      widget.onCompliment?.call(p);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: GataColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: GataColors.rose.withValues(alpha: 0.25),
                            width: 1),
                      ),
                      child: Text(p,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: GataColors.textPrimary,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: custom,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                          hintText: 'Write something sweet…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (custom.text.trim().isNotEmpty) {
                        _sendCompliment(custom.text.trim());
                        widget.onCompliment?.call(custom.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: GataColors.blush,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heartBurst() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _heartCtrl,
          builder: (_, _) {
            if (_heartCtrl.value == 0) return const SizedBox.shrink();
            return Center(
              child: Transform.translate(
                offset: Offset(0, _heartY.value),
                child: Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: const Text('❤️',
                        style: TextStyle(
                          fontSize: 90,
                          shadows: [
                            Shadow(
                              color: Color(0x66E8A0B4),
                              blurRadius: 32,
                              offset: Offset(0, 6),
                            ),
                          ],
                        )),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _loveMessage() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _msgCtrl,
          builder: (_, _) {
            if (_msgCtrl.value == 0) return const SizedBox.shrink();
            return Opacity(
              opacity: _msgOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _msgY.value),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: GataColors.roseDark,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: GataColors.rose.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'She feels your love 💕',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── BACK FACE ────────────────────────────────────────────

  Widget _buildBack() {
    final gradient = widget.isDemo
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.30, 0.78, 1.0],
            colors: [
              Color(0xFFFFAE91),
              Color(0xFFFF7F50),
              Color(0xFFFFE4C4),
              Color(0xFFFFB9A0),
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [GataColors.rose, GataColors.lavender],
            stops: [0.0, 1.0],
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _backHeader(),
          const SizedBox(height: 20),
          _storySection(),
          const Spacer(),
          _complimentSection(),
          const SizedBox(height: 16),
          _flipBackButton(),
        ],
      ),
    );
  }

  Widget _backHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.25),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Center(
            child: Text(widget.author.emoji,
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.author.name,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.verified_rounded,
                    size: 14, color: Colors.white),
              ],
            ),
            Text(
              widget.isDemo ? 'just now' : _timeAgo(widget.post.time),
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _storySection() {
    final text = widget.post.caption.isNotEmpty
        ? widget.post.caption
        : (widget.isDemo
            ? 'This is where the story lives — what the moment felt like, what made her smile, or just a little note for you.'
            : 'No caption yet.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Her Story',
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '"$text"',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 1.55,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _complimentSection() {
    if (widget.isDemo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliments appear here',
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          _complimentPill('You look gorgeous 💕'),
        ],
      );
    }

    return StreamBuilder<List<Compliment>>(
      stream: FirestoreService.watchCompliments(widget.post.id),
      builder: (context, snap) {
        final compliments = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compliments.isEmpty ? 'No compliments yet' : 'Compliments',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.65),
                letterSpacing: 0.8,
              ),
            ),
            if (compliments.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: compliments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _complimentPill(compliments[i].text),
                ),
              ),
            ],
            if (_sentCompliment != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Sent! She\'ll love it 💕',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _complimentPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _flipBackButton() {
    return Center(
      child: GestureDetector(
        onTap: _flip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.40), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flip_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Flip back',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays}d ago';
  }
}

// ── Loading skeleton ──────────────────────────────────────────

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox();

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 950))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.25, end: 0.65)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        color: Color.fromRGBO(36, 36, 36, _anim.value),
      ),
    );
  }
}
