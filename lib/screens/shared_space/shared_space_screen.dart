import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';
import '../auth/invite_card_screen.dart';

class SharedSpaceScreen extends StatelessWidget {
  const SharedSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Ours'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded, color: GataColors.roseDark),
              onPressed: () => _confirmSignOut(context, app),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _counterHero(app),
            const SizedBox(height: 18),
            _inviteCard(context, app),
            const SizedBox(height: 18),
            _noteCard(context, app),
            const SizedBox(height: 18),
            _bucketCard(context, app),
          ],
        ),
      ),
    );
  }

  Widget _counterHero(AppState app) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: GataColors.dusk,
        borderRadius: BorderRadius.circular(28),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          Text('${app.userFor(Sender.me).name}  &  ${app.userFor(Sender.her).name}',
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text('${app.daysTogether}',
              style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1)),
          Text('days together 💞',
              style: GoogleFonts.nunito(
                  color: GataColors.surfaceFloat,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          if (app.anniversary != null) ...[
            const SizedBox(height: 6),
            Text('since ${DateFormat('MMMM d, y').format(app.anniversary!)}',
                style: GoogleFonts.nunito(
                    color: GataColors.surfaceFloat,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _inviteCard(BuildContext context, AppState app) {
    final her = app.userFor(Sender.her);
    return GestureDetector(
      onTap: () { Haptic.medium(); Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const InviteCardScreen())); },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GataColors.surfaceFloat,
          borderRadius: BorderRadius.circular(24),
          boxShadow: kSoftShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: GataColors.blush),
              child: const Center(
                  child: Text('💌', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite ${her.name}',
                      style: GoogleFonts.nunito(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: GataColors.textPrimary)),
                  Text('Send her the invitation to join your space',
                      style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: GataColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: GataColors.roseDark),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(BuildContext context, AppState app) {
    return _card(
      title: 'Our note',
      trailing: const Icon(Icons.edit_rounded,
          size: 18, color: GataColors.roseDark),
      onTapTitle: () => _editNote(context, app),
      child: GestureDetector(
        onTap: () { Haptic.light(); _editNote(context, app); },
        child: Text(
          app.spaceNote.isEmpty
              ? 'Tap to leave a little love note for each other…'
              : app.spaceNote,
          style: GoogleFonts.nunito(
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: app.spaceNote.isEmpty
                  ? GataColors.textMuted
                  : GataColors.textPrimary),
        ),
      ),
    );
  }

  Widget _bucketCard(BuildContext context, AppState app) {
    return _card(
      title: 'Bucket list',
      trailing: GestureDetector(
        onTap: () { Haptic.medium(); _addBucket(context, app); },
        child: const Icon(Icons.add_circle_rounded,
            color: GataColors.rose, size: 24),
      ),
      child: Column(
        children: [
          if (app.bucket.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Add things you want to do together ✨',
                  style: GoogleFonts.nunito(
                      color: GataColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ),
          ...app.bucket.map((b) => Dismissible(
                key: ValueKey(b.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: GataColors.roseDark),
                ),
                onDismissed: (_) => app.removeBucket(b.id),
                child: InkWell(
                  onTap: () { Haptic.light(); app.toggleBucket(b.id); },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          b.done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: b.done
                              ? GataColors.rose
                              : GataColors.dividerColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(b.title,
                              style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: b.done
                                      ? GataColors.textMuted
                                      : GataColors.textPrimary,
                                  decoration: b.done
                                      ? TextDecoration.lineThrough
                                      : null)),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
    VoidCallback? onTapTitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(24),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(),
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: GataColors.roseDark)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  void _editNote(BuildContext context, AppState app) {
    final c = TextEditingController(text: app.spaceNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GataColors.surfaceFloat,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Our note',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: GataColors.textPrimary)),
        content: TextField(
          controller: c,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Write something sweet…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: GataColors.textMuted))),
          ElevatedButton(
              onPressed: () {
                app.setSpaceNote(c.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  void _addBucket(BuildContext context, AppState app) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GataColors.surfaceFloat,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add to bucket list',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: GataColors.textPrimary)),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              const InputDecoration(hintText: 'e.g. Watch the sunrise together'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: GataColors.textMuted))),
          ElevatedButton(
              onPressed: () {
                app.addBucketItem(c.text);
                Navigator.pop(ctx);
              },
              child: const Text('Add')),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppState app) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GataColors.surfaceFloat,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign out?',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700, color: GataColors.textPrimary)),
        content: Text(
            'You\'ll need to sign back in. Your messages and photos stay safe in the cloud.',
            style: GoogleFonts.nunito(
                color: GataColors.textSecondary, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Stay',
                  style: TextStyle(color: GataColors.textMuted))),
          ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await app.signOut();
                await AuthService.signOut(); // clears Firebase session → _Root shows login
              },
              child: const Text('Sign out')),
        ],
      ),
    );
  }
}
