import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/haptic_service.dart';
import '../state/app_state.dart';
import '../theme/gata_theme.dart';

class QuickReactions extends StatelessWidget {
  const QuickReactions({super.key});

  static const _uuid = Uuid();

  void _send(BuildContext context, ReactionType type) {
    Haptic.love();
    final app = context.read<AppState>();
    final reaction = QuickReaction(
      id: _uuid.v4(),
      sender: app.activeSender,
      type: type,
      time: DateTime.now(),
    );
    FirestoreService.sendReaction(reaction);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type.emoji} ${type.label} sent! 💕',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(60, 0, 60, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: GataColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ReactionType.values.map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _ReactionPill(
            emoji: type.emoji,
            label: type.label,
            onTap: () => _send(context, type),
          ),
        );
      }).toList(),
    );
  }
}

class _ReactionPill extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ReactionPill({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ReactionPill> createState() => _ReactionPillState();
}

class _ReactionPillState extends State<_ReactionPill>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: GataColors.surfaceFloat,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: GataColors.rose.withValues(alpha: 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: GataColors.rose.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GataColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
