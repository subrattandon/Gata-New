import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/gata_theme.dart';

/// WhatsApp-style message status ticks for outgoing messages.
///
/// ✓  white/muted = sent (written to Firestore)
/// ✓✓ white      = delivered (partner's device received it)
/// ✓✓ bright pink = seen (partner opened the chat after this message)
class MsgTicks extends StatelessWidget {
  const MsgTicks({super.key, required this.status});
  final MsgStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MsgStatus.sent:
        return _tick(1, Colors.white.withValues(alpha: 0.5));
      case MsgStatus.delivered:
        return _tick(2, Colors.white.withValues(alpha: 0.7));
      case MsgStatus.seen:
        // Bright white with pink shadow for visibility on pink bubbles
        return _seenTick();
    }
  }

  Widget _tick(int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : -5),
            child: Icon(Icons.done_rounded, size: 13, color: color),
          ),
      ],
    );
  }

  Widget _seenTick() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 2; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : -5),
            child: Stack(
              children: [
                // Subtle shadow for contrast on pink gradient
                Icon(Icons.done_rounded, size: 13,
                    color: Colors.black.withValues(alpha: 0.2)),
                const Icon(Icons.done_rounded, size: 13, color: Colors.white),
              ],
            ),
          ),
      ],
    );
  }
}
