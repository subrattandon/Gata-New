import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/haptic_service.dart';
import '../../theme/gata_theme.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  static const _questions = [
    'What was your first thought when you saw me?',
    'Which moment with me would you relive forever?',
    'What is one tiny thing I do that you love?',
    'Where should we travel together next?',
    'What song reminds you of us?',
    'What is your favourite memory of us so far?',
    'If we had a free day together, how would we spend it?',
    'What made you fall for me?',
    'What is one thing you want us to try together?',
    'Describe us in three words.',
    'What is your favourite thing about our mornings?',
    'What does “home” feel like with me?',
  ];

  static const _wyr = [
    ['Forehead kisses 😚', 'Long hugs 🤗'],
    ['Beach sunset 🌅', 'Mountain cabin 🏔️'],
    ['Movie night in 🍿', 'Dancing out 💃'],
    ['Breakfast in bed 🥐', 'Midnight snacks 🌙'],
    ['Handwritten letters 💌', 'Long voice notes 🎙️'],
    ['Stargazing ✨', 'Rainy day cuddles 🌧️'],
  ];

  final _rng = Random();
  late int _qIndex = _rng.nextInt(_questions.length);
  late int _wIndex = _rng.nextInt(_wyr.length);
  int _mode = 0; // 0 = questions, 1 = would you rather

  void _next() {
    Haptic.heavy();
    setState(() {
      if (_mode == 0) {
        _qIndex = (_qIndex + 1 + _rng.nextInt(_questions.length - 1)) %
            _questions.length;
      } else {
        _wIndex =
            (_wIndex + 1 + _rng.nextInt(_wyr.length - 1)) % _wyr.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Play')),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            children: [
              _modeSwitch(),
              const SizedBox(height: 22),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                        scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                        child: child),
                  ),
                  child: _mode == 0
                      ? _questionCard(key: ValueKey('q$_qIndex'))
                      : _wyrCard(key: ValueKey('w$_wIndex')),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_mode == 0 ? 'Next question  →' : 'Shuffle  🎲'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          _segment('💬 Questions', 0),
          _segment('🤔 Would You Rather', 1),
        ],
      ),
    );
  }

  Widget _segment(String label, int index) {
    final on = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () { Haptic.select(); setState(() => _mode = index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: on ? GataColors.blush : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : GataColors.textMuted)),
        ),
      ),
    );
  }

  Widget _questionCard({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: GataColors.dusk,
        borderRadius: BorderRadius.circular(32),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💞', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 24),
          Text(_questions[_qIndex],
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 24),
          Text('take turns answering',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _wyrCard({Key? key}) {
    final pair = _wyr[_wIndex];
    return Column(
      key: key,
      children: [
        Expanded(child: _wyrOption(pair[0], GataColors.blush)),
        const SizedBox(height: 14),
        Text('or',
            style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: GataColors.textSecondary)),
        const SizedBox(height: 14),
        Expanded(child: _wyrOption(pair[1], GataColors.lavenderGlow)),
      ],
    );
  }

  Widget _wyrOption(String text, Gradient g) {
    return GestureDetector(
      onTap: () {
        Haptic.love();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 1100),
            behavior: SnackBarBehavior.floating,
            backgroundColor: GataColors.roseDark,
            content: Text('Good choice 💕',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ));
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: g,
          borderRadius: BorderRadius.circular(28),
          boxShadow: kSoftShadow,
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }
}
