import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/gata_theme.dart';

/// WhatsApp-style message status ticks for outgoing messages.
///
/// ✓  grey   = sent (written to Firestore)
/// ✓✓ grey   = delivered (partner's device received it)
/// ✓✓ pink   = seen (partner opened the chat after this message)
class MsgTicks extends StatelessWidget {
  const MsgTicks({super.key, required this.status});
  final MsgStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MsgStatus.sent:
        return _tick(1, Colors.white60);
      case MsgStatus.delivered:
        return _tick(2, Colors.white70);
      case MsgStatus.seen:
        return _tick(2, GataColors.roseLight);
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
}
