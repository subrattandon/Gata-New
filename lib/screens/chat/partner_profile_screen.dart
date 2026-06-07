import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/haptic_service.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';

class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _lockChat = false;
  bool _headerPressed = false;

  late final AnimationController _entranceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final partner = app.userFor(Sender.her);
    final me = app.userFor(Sender.me);
    final msgCount = app.messages.length;
    final postCount = app.posts.length;
    final bucketCount = app.bucket.length;
    final photos = app.photoPosts.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Blurred glassmorphism background ──────────────────
          _Background(emoji: partner.emoji),

          // ── Scrollable content ────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _appBar(context),
                      const SizedBox(height: 28),
                      _profileHeader(context, partner, me),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _statsCard(msgCount, postCount, bucketCount),
                            const SizedBox(height: 12),
                            if (photos.isNotEmpty) ...[
                              _mediaCard(context, photos, postCount),
                              const SizedBox(height: 12),
                            ],
                            _settingsCard(context),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Top app bar ──────────────────────────────────────────────

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            icon: Icons.chevron_left_rounded,
            iconSize: 26,
            onTap: () {
              Haptic.select();
              Navigator.of(context).pop();
            },
          ),
          _GlassButton(
            icon: Icons.more_vert_rounded,
            iconSize: 22,
            onTap: () {
              Haptic.light();
              _openMoreSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // ── Profile header ───────────────────────────────────────────

  Widget _profileHeader(
      BuildContext context, AppUser partner, AppUser me) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _headerPressed = true),
      onTapUp: (_) {
        setState(() => _headerPressed = false);
        Haptic.select();
      },
      onTapCancel: () => setState(() => _headerPressed = false),
      child: AnimatedScale(
        scale: _headerPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          children: [
            // Avatar with online indicator
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6), width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 30,
                          offset: Offset(0, 10)),
                    ],
                  ),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF1E1E1E),
                      child: Center(
                        child: Text(partner.emoji,
                            style: const TextStyle(fontSize: 48)),
                      ),
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: _OnlineDot(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              partner.name,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              partner.email,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFD0D0D0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats card ───────────────────────────────────────────────

  Widget _statsCard(int msgs, int posts, int bucket) {
    return _GlassCard(
      child: Row(
        children: [
          _StatItem(
            value: msgs.toString(),
            label: 'Messages',
            onTap: () => Haptic.light(),
          ),
          _VerticalDivider(),
          _StatItem(
            value: posts.toString(),
            label: 'Posts',
            onTap: () => Haptic.light(),
          ),
          _VerticalDivider(),
          _StatItem(
            value: bucket.toString(),
            label: 'Bucket',
            onTap: () => Haptic.light(),
          ),
        ],
      ),
    );
  }

  // ── Media card ───────────────────────────────────────────────

  Widget _mediaCard(BuildContext context, List<Post> photos, int total) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Media & Photos',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: const Color(0xFF8A8A8A), size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...photos.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final isLast = i == photos.length - 1 && total > 4;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 90,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: GataColors.surfaceFloat,
                              child: Center(
                                child: Text('📷',
                                    style:
                                        const TextStyle(fontSize: 24)),
                              ),
                            ),
                            if (isLast)
                              Container(
                                color: Colors.black.withValues(alpha: 0.6),
                                child: Center(
                                  child: Text(
                                    '+${total - 3}',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ── Settings card ────────────────────────────────────────────

  Widget _settingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090909),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.notifications_outlined,
            iconColor: const Color(0xFFFF9500),
            label: 'Notifications',
            onTap: () => Haptic.light(),
          ),
          _Divider(),
          _SettingsRow(
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFF30D158),
            label: 'Media Visibility',
            onTap: () => Haptic.light(),
          ),
          _Divider(),
          _SettingsRow(
            icon: Icons.bookmark_outline_rounded,
            iconColor: const Color(0xFF007AFF),
            label: 'Bookmarked',
            onTap: () => Haptic.light(),
          ),
          _Divider(),
          _LockChatRow(
            value: _lockChat,
            onChanged: (v) {
              Haptic.light();
              setState(() => _lockChat = v);
            },
          ),
        ],
      ),
    );
  }

  // ── More sheet ───────────────────────────────────────────────

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SheetItem(
              icon: Icons.share_outlined,
              label: 'Share Contact',
              onTap: () => Navigator.pop(context),
            ),
            _SheetItem(
              icon: Icons.block_outlined,
              label: 'Block',
              onTap: () => Navigator.pop(context),
              color: const Color(0xFFFF453A),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Background widget ──────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox.expand(
      child: Stack(
        children: [
          // Warm dark base
          Container(color: const Color(0xFF1A0F0A)),
          // Colored glow orbs
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x55E8A0B4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33B8A0D4), Colors.transparent],
                ),
              ),
            ),
          ),
          // Large emoji watermark
          Positioned(
            top: size.height * 0.06,
            left: 0,
            right: 0,
            child: Center(
              child: Text(emoji,
                  style: TextStyle(fontSize: size.height * 0.30)),
            ),
          ),
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.expand(),
          ),
          // Gradient fade to black at bottom
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.6, 1.0],
                colors: [
                  Color(0xB3462D23), // rgba(70,45,35,0.70)
                  Color(0xC0191414), // rgba(25,20,20,0.75)
                  Color(0xD9000000), // rgba(0,0,0,0.85)
                  Color(0xEB000000), // rgba(0,0,0,0.92)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass card ────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Glass button ──────────────────────────────────────────────

class _GlassButton extends StatefulWidget {
  const _GlassButton(
      {required this.icon, required this.onTap, this.iconSize = 22});
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
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
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
              child: Icon(widget.icon,
                  color: Colors.white, size: widget.iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat item ────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.value, required this.label, required this.onTap});
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFBEBEBE),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings row ─────────────────────────────────────────────

class _SettingsRow extends StatefulWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _pressed ? 0.7 : 1.0,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF5A5A5A), size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lock chat row ────────────────────────────────────────────

class _LockChatRow extends StatelessWidget {
  const _LockChatRow({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFFF375F), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Lock Chat',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: GataColors.successGreen,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF5A5A5A),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Online dot (animated pulse) ──────────────────────────────

class _OnlineDot extends StatefulWidget {
  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFF8A3D),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A3D)
                  .withValues(alpha: 0.4 + _c.value * 0.4),
              blurRadius: 6 + _c.value * 6,
              spreadRadius: _c.value * 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color = Colors.white});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w400, color: color)),
      onTap: onTap,
    );
  }
}
