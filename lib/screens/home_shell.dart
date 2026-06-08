import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/haptic_service.dart';
import '../state/app_state.dart';
import '../theme/gata_theme.dart';
import '../widgets/quick_reactions.dart';
import 'chat/chat_screen.dart';
import 'posts/posts_screen.dart';
import 'reaction_overlay.dart';
import 'shared_space/shared_space_screen.dart';
import 'mood/mood_screen.dart';
import 'touch/touch_screen.dart';
import 'games/games_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // 0=Posts, 1=Ours, 2=Mood, 3=Play — Chat is pushed as a separate route.
  int _currentIndex = 0;

  static const _screens = [
    PostsScreen(),
    SharedSpaceScreen(),
    MoodScreen(),
    GamesScreen(),
  ];

  void _onNavTap(BuildContext context, int navIndex) {
    Haptic.select();
    if (navIndex == 0) {
      // Chat: full-screen push — floating nav disappears naturally.
      Navigator.of(context).push(_chatRoute());
      return;
    }
    setState(() => _currentIndex = navIndex - 1);
  }

  Route<void> _chatRoute() => PageRouteBuilder<void>(
        pageBuilder: (_, animation, _) => const ChatScreen(),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    // Responsive nav horizontal margin: 5% each side, min 16, max 28.
    final navHPad = (mq.size.width * 0.05).clamp(16.0, 28.0);

    final navH = mq.size.width > 400 ? 66.0 : 62.0;

    return Scaffold(
      body: Stack(
        children: [
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(
                bottom: mq.padding.bottom + navH + 16,
              ),
              viewPadding: mq.viewPadding.copyWith(
                bottom: mq.viewPadding.bottom + navH + 16,
              ),
            ),
            child: _screens[_currentIndex],
          ),
          Positioned(
            left: navHPad,
            right: navHPad,
            bottom: bottomInset + 16,
            child: _FloatingNavBar(
              // nav indices: 0=Chat,1=Posts,2=Ours,3=Mood,4=Play
              activeNavIndex: _currentIndex + 1,
              onTap: (i) => _onNavTap(context, i),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav data ────────────────────────────────────────────────

const _kNavItems = [
  (icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
  (icon: Icons.grid_view_outlined, label: 'Posts'),
  (icon: Icons.favorite_border_rounded, label: 'Ours'),
  (icon: Icons.mood_outlined, label: 'Mood'),
  (icon: Icons.sports_esports_outlined, label: 'Play'),
];

// ── Floating nav bar ─────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int activeNavIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar(
      {required this.activeNavIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Slightly taller on large phones.
    final navH = screenW > 400 ? 66.0 : 62.0;

    return Container(
      height: navH,
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x50000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_kNavItems.length, (i) {
                return _NavItem(
                  icon: _kNavItems[i].icon,
                  label: _kNavItems[i].label,
                  // Chat (index 0) is never "active" in the shell.
                  isActive: i != 0 && activeNavIndex == i,
                  onTap: () => onTap(i),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          _FabButton(
            onTap: () => Haptic.medium(),
          ),
        ],
      ),
    );
  }
}

// ── Nav item ─────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isActive)
                    Container(
                      width: 32,
                      height: 22,
                      decoration: BoxDecoration(
                        color: GataColors.badgeRed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.isActive
                        ? GataColors.textPrimary
                        : GataColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: widget.isActive
                      ? GataColors.textPrimary
                      : GataColors.textMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────

class _FabButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FabButton({required this.onTap});

  @override
  State<_FabButton> createState() => _FabButtonState();
}

class _FabButtonState extends State<_FabButton> {
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
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: GataColors.surfaceElevated,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add,
              color: GataColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}
