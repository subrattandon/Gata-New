import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/haptic_service.dart';
import '../../theme/gata_theme.dart';
import '../../widgets/floating_hearts.dart';
import 'onboarding_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: const Interval(0.2, 1, curve: Curves.easeOut));
  late final Animation<double> _pop =
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GataColors.screen),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingHearts()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    ScaleTransition(
                      scale: _pop,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: GataColors.dusk,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x55C2607A),
                              blurRadius: 40,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('💞', style: TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fade,
                      child: Column(
                        children: [
                          Text(
                            'Gata',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: GataColors.textPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Just us two.\nOur chats, our photos, our world.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 17,
                              height: 1.5,
                              color: GataColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _fade,
                      child: SizedBox(
                        width: double.infinity,
                        child: _GradientButton(
                          label: 'Start our story  →',
                          onTap: () {
                            Haptic.heavy();
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 420),
                                pageBuilder: (_, a, _) => FadeTransition(
                                  opacity: a,
                                  child: const OnboardingScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        'No strangers. No feeds. No noise.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: GataColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: GataColors.blush,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55E8A0B4),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
