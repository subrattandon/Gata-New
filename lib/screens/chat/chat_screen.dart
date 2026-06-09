import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../services/firestore_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';
import '../../widgets/chat_bubble.dart';
import 'partner_profile_screen.dart';
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        if (animated) {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scroll.jumpTo(0);
        }
      }
    });
  }
  int _lastMsgCount = 0;
  AppState? _appState;
  @override
  void initState() {
    super.initState();
    final myEmail = AuthService.myEmail();
    if (myEmail.isNotEmpty) {
      FirestoreService.markSeen(myEmail);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
      _appState = context.read<AppState>();
      _lastMsgCount = _appState!.messages.length;
      _appState!.addListener(_onMessagesChanged);
    });
  }
  void _onMessagesChanged() {
    final app = context.read<AppState>();
    if (app.messages.length > _lastMsgCount) {
      _lastMsgCount = app.messages.length;
      _scrollToBottom();
    }
  }
  @override
  void dispose() {
    context.read<AppState>().removeListener(_onMessagesChanged);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }
  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Haptic.medium();
    context.read<AppState>().sendMessage(text);
    _controller.clear();
    setState(() {});
    _scrollToBottom();
  }
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final partner = app.userFor(Sender.her);
    final items = _withDateSeparators(app.messages);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) Haptic.light();
      },
      child: Scaffold(
        backgroundColor: GataColors.bg,
        // Keyboard pushes body up automatically.
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(context, app, partner),
        body: Column(
          children: [
            Expanded(
              child: app.messages.isEmpty
                  ? _empty(partner)
                  : StreamBuilder<DateTime?>(
                      stream:
                          FirestoreService.watchLastSeen(partner.email),
                      builder: (context, seenSnap) {
                        final herLastSeen = seenSnap.data;
                        return ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final item = items[i];
                            if (item is String) {
                              return _DateChip(label: item);
                            }
                            var m = item as Message;
                            if (m.sender == Sender.me &&
                                herLastSeen != null) {
                              if (herLastSeen.isAfter(m.time)) {
                                m = m.copyWith(status: MsgStatus.seen);
                              } else if (m.status == MsgStatus.sent) {
                                m = m.copyWith(
                                    status: MsgStatus.delivered);
                              }
                            }
                            return ChatBubble(
                              message: m,
                              isMine: m.sender == Sender.me,
                              onReact: (r) =>
                                  app.reactToMessage(m.id, r),
                            );
                          },
                        );
                      },
                    ),
            ),
            _InputBar(
              controller: _controller,
              onSend: _send,
              asPartner: app.activeSender == Sender.her,
              partnerName: partner.name,
              onChanged: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppState app, AppUser partner) {
    return AppBar(
      backgroundColor: GataColors.surface,
      elevation: 0,
      titleSpacing: 0,
      // automaticallyImplyLeading: true (default) adds back chevron from theme.
      leadingWidth: 48,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 28),
        color: GataColors.textPrimary,
        tooltip: 'Back',
        onPressed: () {
          Haptic.light();
          Navigator.of(context).pop();
        },
        onLongPress: () => Haptic.select(),
      ),
      title: GestureDetector(
        onTap: () {
          Haptic.select();
          Navigator.of(context).push(PageRouteBuilder<void>(
            pageBuilder: (_, a, _) => FadeTransition(
              opacity: a,
              child: const PartnerProfileScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 260),
          ));
        },
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: GataColors.surfaceFloat,
                shape: BoxShape.circle,
                border: Border.all(
                    color: GataColors.rose.withValues(alpha: 0.35),
                    width: 1.5),
              ),
              child: Center(
                child: Text(partner.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  partner.name,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GataColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: GataColors.successGreen,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'only you two here',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: GataColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        _SenderToggle(
          active: app.activeSender,
          onTap: () {
            Haptic.select();
            final next = app.activeSender.opposite;
            app.setActiveSender(next);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                duration: const Duration(milliseconds: 1200),
                content: Text(
                  next == Sender.me
                      ? 'Typing as you'
                      : 'Preview: ${app.userFor(Sender.her).name}',
                ),
              ));
          },
        ),
        const SizedBox(width: 10),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: GataColors.dividerColor),
      ),
    );
  }
  Widget _empty(AppUser partner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Say something sweet\nto ${partner.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: GataColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
  List<Object> _withDateSeparators(List<Message> msgs) {
    // msgs is newest-first; output newest-first for reverse:true ListView.
    // Date separator goes AFTER the oldest message of each day (renders above in reversed view).
    final out = <Object>[];
    for (var i = 0; i < msgs.length; i++) {
      out.add(msgs[i]);
      final isOldestOfDay =
          i == msgs.length - 1 || !_sameDay(msgs[i + 1].time, msgs[i].time);
      if (isOldestOfDay) out.add(_dateLabel(msgs[i].time));
    }
    return out;
  }
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d').format(t);
  }
}
// ── Date chip ────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: GataColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: GataColors.textMuted,
          ),
        ),
      ),
    );
  }
}
// ── Input bar ────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onChanged;
  final bool asPartner;
  final String partnerName;
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onChanged,
    required this.asPartner,
    required this.partnerName,
  });
  @override
  State<_InputBar> createState() => _InputBarState();
}
class _InputBarState extends State<_InputBar> {
  bool _sendPressed = false;
  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final mq = MediaQuery.of(context);
    // Font scale clamped so UI doesn't break on large accessibility sizes.
    final textScale = mq.textScaler.scale(1.0).clamp(0.85, 1.2);
    return Container(
      decoration: const BoxDecoration(
        color: GataColors.surface,
        border: Border(
            top: BorderSide(color: GataColors.dividerColor, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: GataColors.surfaceFloat,
                  borderRadius: BorderRadius.circular(26),
                  border: widget.asPartner
                      ? Border.all(
                          color:
                              GataColors.lavender.withValues(alpha: 0.55),
                          width: 1.5)
                      : null,
                ),
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => widget.onChanged(),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w500,
                    color: GataColors.textPrimary,
                    fontSize: 15 * textScale,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.asPartner
                        ? 'Reply as ${widget.partnerName}…'
                        : 'Message…',
                    hintStyle: GoogleFonts.nunito(
                        color: GataColors.textMuted,
                        fontSize: 15 * textScale),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    filled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTapDown: (_) => setState(() => _sendPressed = true),
              onTapUp: (_) {
                setState(() => _sendPressed = false);
                widget.onSend();
              },
              onTapCancel: () => setState(() => _sendPressed = false),
              child: AnimatedScale(
                scale: _sendPressed ? 0.88 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: hasText ? GataColors.blush : null,
                    color: hasText ? null : GataColors.surfaceFloat,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText
                        ? Colors.white
                        : GataColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ── Sender toggle ────────────────────────────────────────────
class _SenderToggle extends StatelessWidget {
  const _SenderToggle({required this.active, required this.onTap});
  final Sender active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final asPartner = active == Sender.her;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: asPartner
              ? GataColors.lavender.withValues(alpha: 0.18)
              : GataColors.surfaceFloat,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: asPartner
                ? GataColors.lavender.withValues(alpha: 0.35)
                : GataColors.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: asPartner
                  ? GataColors.lavender
                  : GataColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              asPartner ? 'Her' : 'You',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: asPartner
                    ? GataColors.lavender
                    : GataColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
