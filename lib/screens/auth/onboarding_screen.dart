import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _myName = TextEditingController();
  final _myEmail = TextEditingController();
  final _herName = TextEditingController();
  final _herEmail = TextEditingController();
  String _myEmoji = '💖';
  String _herEmoji = '🌷';
  DateTime? _anniversary;
  bool _submitting = false;

  @override
  void dispose() {
    _myName.dispose();
    _myEmail.dispose();
    _herName.dispose();
    _herEmail.dispose();
    super.dispose();
  }

  bool get _valid =>
      _myName.text.trim().isNotEmpty &&
      _emailOk(_myEmail.text.trim()) &&
      _herName.text.trim().isNotEmpty &&
      _emailOk(_herEmail.text.trim()) &&
      _anniversary != null;

  bool _emailOk(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _anniversary ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'When did your story begin?',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: GataColors.rose,
            onPrimary: Colors.white,
            onSurface: GataColors.darkText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _anniversary = picked);
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() => _submitting = true);
    final app = context.read<AppState>();
    await app.signIn(
      myName: _myName.text.trim(),
      myEmail: _myEmail.text.trim(),
      myEmoji: _myEmoji,
      herName: _herName.text.trim(),
      herEmoji: _herEmoji,
      herEmailAddr: _herEmail.text.trim(),
      anniversaryDate: _anniversary!,
    );
    // Firebase parked for now: enter the app directly instead of gating on the
    // invitation/pairing step. _Root rebuilds into the home shell.
    await app.markPaired();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GataColors.screen),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: GataColors.roseDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your space',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: GataColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Two people. One private app. Sign in with your email — '
                'your partner will use theirs.',
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  height: 1.5,
                  color: GataColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 26),
              _card(
                title: 'You',
                child: Column(
                  children: [
                    _AvatarPicker(
                      selected: _myEmoji,
                      onPick: (e) => setState(() => _myEmoji = e),
                    ),
                    const SizedBox(height: 16),
                    _field(_myName, 'Your name', Icons.person_outline_rounded,
                        onChanged: (_) => setState(() {})),
                    const SizedBox(height: 12),
                    _field(_myEmail, 'Your email', Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {})),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                title: 'Your person',
                child: Column(
                  children: [
                    _AvatarPicker(
                      selected: _herEmoji,
                      onPick: (e) => setState(() => _herEmoji = e),
                    ),
                    const SizedBox(height: 16),
                    _field(_herName, 'Their name',
                        Icons.favorite_outline_rounded,
                        onChanged: (_) => setState(() {})),
                    const SizedBox(height: 12),
                    _field(_herEmail, 'Their email',
                        Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {})),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 14, color: GataColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'If she already has Gata, you connect instantly. '
                            'If not, you send her an invitation.',
                            style: GoogleFonts.nunito(
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: GataColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                title: 'Your anniversary',
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: GataColors.surfaceFloat,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: GataColors.roseDark, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _anniversary == null
                              ? 'Pick the day it began'
                              : DateFormat('MMMM d, y').format(_anniversary!),
                          style: GoogleFonts.nunito(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: _anniversary == null
                                ? GataColors.softGray
                                : GataColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _valid ? _submit : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _valid ? 1 : 0.45,
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: GataColors.blush,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: _valid ? kSoftShadow : null,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            'Enter Gata  💕',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: GataColors.roseDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      onChanged: onChanged,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: GataColors.roseDark, size: 20),
        fillColor: GataColors.surfaceFloat,
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected, required this.onPick});
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kAvatarChoices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final e = kAvatarChoices[i];
          final on = e == selected;
          return GestureDetector(
            onTap: () => onPick(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: on ? GataColors.dusk : null,
                color: on ? null : GataColors.surfaceFloat,
                border: Border.all(
                  color: on ? Colors.transparent : GataColors.roseLight,
                  width: 1.5,
                ),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
            ),
          );
        },
      ),
    );
  }
}
