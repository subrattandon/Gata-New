import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/haptic_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';

class MoodScreen extends StatelessWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final settingFor = app.activeSender;
    final current = settingFor == Sender.me ? app.moodMe : app.moodHer;

    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Mood')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Row(
              children: [
                Expanded(
                    child: _MoodCard(
                        user: app.userFor(Sender.me), mood: app.moodMe)),
                const SizedBox(width: 12),
                Expanded(
                    child: _MoodCard(
                        user: app.userFor(Sender.her), mood: app.moodHer)),
              ],
            ),
            const SizedBox(height: 26),
            Text(
                settingFor == Sender.me
                    ? 'How are you feeling?'
                    : "Set ${app.userFor(Sender.her).name}'s mood (preview)",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: GataColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Use the You/Her switch in Chat to set the other side.',
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GataColors.textMuted)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemCount: kMoods.length,
              itemBuilder: (_, i) {
                final m = kMoods[i];
                final selected = current?.label == m.$2;
                return GestureDetector(
                  onTap: () { Haptic.medium(); app.setMood(settingFor, m.$1, m.$2); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      gradient: selected ? GataColors.blush : null,
                      color: selected ? null : GataColors.surfaceFloat,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: kSoftShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(m.$1, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        Text(m.$2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : GataColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.user, required this.mood});
  final AppUser user;
  final MoodEntry? mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(24),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          Text(user.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(user.name,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: GataColors.textPrimary)),
          const SizedBox(height: 14),
          Text(mood?.emoji ?? '🤍', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(mood?.label ?? 'No mood yet',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GataColors.roseDark)),
          if (mood != null)
            Text(DateFormat('h:mm a').format(mood!.time),
                style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: GataColors.textMuted)),
        ],
      ),
    );
  }
}
