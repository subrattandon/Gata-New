import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/haptic_service.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';
import '../../widgets/floating_hearts.dart';

/// Shown after sign-in when the partner hasn't joined yet.
/// She opens the invitation (link or code) to land in the same private space.
class InviteCardScreen extends StatelessWidget {
  const InviteCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final her = app.userFor(Sender.her);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: GataColors.screen),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingHearts(count: 10)),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () { Haptic.light(); Navigator.of(context).maybePop(); },
                      icon: const Icon(Icons.close_rounded,
                          color: GataColors.roseDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Invite ${her.name} 💌',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: GataColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'We couldn’t find ${her.name} on Gata yet.\n'
                    'Send this invitation so it’s just the two of you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 14.5,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: GataColors.mauve),
                  ),
                  const SizedBox(height: 24),
                  _InvitationCard(app: app, her: her),
                  const SizedBox(height: 22),
                  _shareButton(context, app, her),
                  const SizedBox(height: 12),
                  _copyCodeButton(context, app),
                  const SizedBox(height: 26),
                  _waitingRow(her),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareButton(BuildContext context, AppState app, AppUser her) {
    return GestureDetector(
      onTap: () {
        Haptic.success();
        final msg =
            'Hey ${her.name} 💕 I made us a private space called Gata — '
            'just us, no one else. Join me: ${app.inviteLink}  '
            '(code ${app.inviteCode})';
        Clipboard.setData(ClipboardData(text: msg));
        _toast(context, 'Invitation copied — paste it to her 💌');
      },
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: GataColors.blush,
          borderRadius: BorderRadius.circular(28),
          boxShadow: kSoftShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ios_share_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Copy invitation',
                style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _copyCodeButton(BuildContext context, AppState app) {
    return GestureDetector(
      onTap: () {
        Haptic.success();
        Clipboard.setData(ClipboardData(text: app.inviteCode));
        _toast(context, 'Code ${app.inviteCode} copied');
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GataColors.roseLight, width: 1.5),
        ),
        child: Text('Copy code only',
            style: GoogleFonts.nunito(
                color: GataColors.roseDark,
                fontSize: 14.5,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _waitingRow(AppUser her) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Pulse(),
        const SizedBox(width: 10),
        Text('Waiting for ${her.name} to join…',
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: GataColors.mauve)),
      ],
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GataColors.roseDark,
        content: Text(msg,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      ));
  }

}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.app, required this.her});
  final AppState app;
  final AppUser her;

  @override
  Widget build(BuildContext context) {
    final me = app.userFor(Sender.me);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        gradient: GataColors.dusk,
        borderRadius: BorderRadius.circular(30),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          Text('YOU’RE INVITED',
              style: GoogleFonts.nunito(
                  fontSize: 12,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _avatar(me.emoji),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('💞', style: const TextStyle(fontSize: 26)),
              ),
              _avatar(her.emoji),
            ],
          ),
          const SizedBox(height: 18),
          Text('${me.name} wants to start\nyour private space',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 21,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text('INVITE CODE',
                    style: GoogleFonts.nunito(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(app.inviteCode,
                    style: GoogleFonts.nunito(
                        fontSize: 30,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('for ${her.email}',
              style: GoogleFonts.nunito(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _avatar(String emoji) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      );
}

class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
            color: GataColors.rose, shape: BoxShape.circle),
      ),
    );
  }
}
