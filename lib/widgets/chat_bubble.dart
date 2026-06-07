import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/haptic_service.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/gata_theme.dart';
import 'msg_ticks.dart';

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReact,
  });

  final Message message;
  final bool isMine;
  final ValueChanged<String?> onReact;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Bubble: max 78% screen width, never narrower than 60px.
    final maxBubbleWidth = (mq.size.width * 0.78).clamp(60.0, 380.0);
    final textScale = mq.textScaler.scale(1.0).clamp(0.85, 1.2);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(widget.isMine ? 20 : 5),
      bottomRight: Radius.circular(widget.isMine ? 5 : 20),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: widget.message.reaction != null ? 16 : 3,
        // Responsive horizontal indent: 16% each side for sender/receiver.
        left: widget.isMine ? mq.size.width * 0.16 : 14,
        right: widget.isMine ? 14 : mq.size.width * 0.16,
      ),
      child: Align(
        alignment: widget.isMine
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onLongPress: () {
            Haptic.impact();
            _openReactions(context);
          },
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient:
                          widget.isMine ? GataColors.blush : null,
                      color: widget.isMine
                          ? null
                          : GataColors.surfaceFloat,
                      borderRadius: radius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message.text,
                          style: GoogleFonts.nunito(
                            fontSize: 15 * textScale,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('h:mm a')
                                  .format(widget.message.time),
                              style: GoogleFonts.nunito(
                                fontSize: 10.5 * textScale,
                                fontWeight: FontWeight.w500,
                                color: widget.isMine
                                    ? Colors.white
                                        .withValues(alpha: 0.60)
                                    : GataColors.textMuted,
                              ),
                            ),
                            if (widget.isMine) ...[
                              const SizedBox(width: 4),
                              MsgTicks(status: widget.message.status),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.message.reaction != null)
                  Positioned(
                    bottom: -14,
                    right: widget.isMine ? null : 8,
                    left: widget.isMine ? 8 : null,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: GataColors.surfaceElevated,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(widget.message.reaction!,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openReactions(BuildContext context) {
    const reactions = ['❤️', '😍', '😂', '🥺', '😮', '👍'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: GataColors.surfaceFloat,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final r in reactions)
              GestureDetector(
                onTap: () {
                  Haptic.medium();
                  widget.onReact(
                      widget.message.reaction == r ? null : r);
                  Navigator.pop(context);
                },
                child: AnimatedScale(
                  scale: widget.message.reaction == r ? 1.3 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(r,
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
