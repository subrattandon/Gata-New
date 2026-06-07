import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../theme/gata_theme.dart';
import '../../widgets/floating_hearts.dart';

/// Firebase email + password sign-in / sign-up.
/// Only kAllowedEmails can proceed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get _valid =>
      _email.text.trim().isNotEmpty && _pass.text.length >= 6;

  Future<void> _submit() async {
    if (!_valid || _loading) return;
    Haptic.heavy();
    setState(() { _loading = true; _error = null; });
    final err = await AuthService.signUpOrIn(
        _email.text.trim(), _pass.text);
    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    }
    // On success, authStateChanges fires and _Root rebuilds automatically.
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GataColors.screen),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingHearts(count: 8)),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 32),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: GataColors.dusk,
                        boxShadow: [BoxShadow(
                          color: Color(0x55C2607A),
                          blurRadius: 30, offset: Offset(0, 14))],
                      ),
                      child: const Center(
                          child: Text('💞', style: TextStyle(fontSize: 44))),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Sign in to Gata',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: GataColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Only you two can sign in.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: GataColors.textSecondary)),
                  const SizedBox(height: 34),
                  _field(_email, 'Email', Icons.alternate_email_rounded,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _passField(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1515),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFE57373), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.nunito(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC62828))),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _valid ? _submit : null,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _valid ? 1 : 0.45,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: GataColors.blush,
                          borderRadius: BorderRadius.circular(29),
                          boxShadow: _valid ? kSoftShadow : null,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text('Enter Gata 💕',
                                style: GoogleFonts.nunito(
                                    color: Colors.white, fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'First time? Use your email + choose a password.\n'
                    'Your account is created automatically.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: GataColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: GataColors.roseDark, size: 20),
        fillColor: GataColors.surfaceFloat,
      ),
    );
  }

  Widget _passField() {
    return TextField(
      controller: _pass,
      obscureText: _obscure,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _submit(),
      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Password (min 6 chars)',
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: GataColors.roseDark, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: GataColors.textMuted, size: 20),
          onPressed: () { Haptic.select(); setState(() => _obscure = !_obscure); },
        ),
        fillColor: GataColors.surfaceFloat,
      ),
    );
  }
}
