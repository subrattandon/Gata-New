import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../models/models.dart';
import '../../services/haptic_service.dart';
import '../../services/music_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';

class MusicReelsScreen extends StatefulWidget {
  const MusicReelsScreen({super.key});

  @override
  State<MusicReelsScreen> createState() => _MusicReelsScreenState();
}

class _MusicReelsScreenState extends State<MusicReelsScreen> {
  late String _selectedMood;
  late List<SongCard> _songs;
  late PageController _pageController;
  int _currentPage = 0;

  final Map<int, YoutubePlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _selectedMood = app.moodMe?.label ?? 'Loved';
    _songs = MusicService.songsForMood(_selectedMood);
    _pageController = PageController();
    _initController(0);
  }

  YoutubePlayerController _initController(int index) {
    if (_controllers.containsKey(index)) return _controllers[index]!;
    if (index >= _songs.length) return _controllers.values.first;

    final controller = YoutubePlayerController.fromVideoId(
      videoId: _songs[index].youtubeId,
      autoPlay: index == _currentPage,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: false,
        loop: true,
        showVideoAnnotations: false,
        enableCaption: false,
        pointerEvents: PointerEvents.auto,
      ),
    );
    _controllers[index] = controller;
    return controller;
  }

  void _onMoodChanged(String mood) {
    if (mood == _selectedMood) return;
    Haptic.medium();
    _disposeAllControllers();
    setState(() {
      _selectedMood = mood;
      _songs = MusicService.songsForMood(mood);
      _currentPage = 0;
      _pageController.jumpToPage(0);
      _initController(0);
    });
  }

  void _onPageChanged(int page) {
    Haptic.light();
    // Pause previous
    _controllers[_currentPage]?.pauseVideo();
    setState(() => _currentPage = page);
    // Init and play new
    _initController(page);
    _controllers[page]?.playVideo();
    // Pre-init next
    if (page + 1 < _songs.length) _initController(page + 1);
  }

  void _disposeAllControllers() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeAllControllers();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── Vertical reels PageView ──
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _songs.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                _initController(index);
                return _MusicReelCard(
                  song: _songs[index],
                  controller: _controllers[index]!,
                  isActive: index == _currentPage,
                );
              },
            ),

            // ── Top gradient overlay for mood chips ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(0, mq.padding.top + 8, 0, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xDD0B0B0B),
                      Color(0x000B0B0B),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Music Vibes',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MoodChipBar(
                      selectedMood: _selectedMood,
                      onMoodChanged: _onMoodChanged,
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom gradient with song info ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, 40, 20, mq.padding.bottom + 80),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xEE0B0B0B),
                      Color(0x000B0B0B),
                    ],
                  ),
                ),
                child: _songs.isNotEmpty
                    ? _SongInfo(song: _songs[_currentPage])
                    : const SizedBox.shrink(),
              ),
            ),

            // ── Right side action buttons ──
            Positioned(
              right: 12,
              bottom: mq.padding.bottom + 160,
              child: _ActionButtons(
                song: _songs.isNotEmpty ? _songs[_currentPage] : null,
              ),
            ),

            // ── Page indicator dots ──
            Positioned(
              left: 12,
              top: mq.size.height * 0.45,
              child: _PageIndicator(
                total: _songs.length,
                current: _currentPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mood chip bar ──────────────────────────────────────────

class _MoodChipBar extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<String> onMoodChanged;

  const _MoodChipBar({
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kMoods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final mood = kMoods[i];
          final selected = mood.$2 == selectedMood;
          return GestureDetector(
            onTap: () => onMoodChanged(mood.$2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected ? GataColors.dusk : null,
                color: selected ? null : GataColors.surfaceFloat.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? GataColors.rose.withValues(alpha: 0.6)
                      : GataColors.dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mood.$1, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    mood.$2,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : GataColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Music Reel Card ────────────────────────────────────────

class _MusicReelCard extends StatelessWidget {
  final SongCard song;
  final YoutubePlayerController controller;
  final bool isActive;

  const _MusicReelCard({
    required this.song,
    required this.controller,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GataColors.bg,
      child: Center(
        child: YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }
}

// ── Song info overlay ──────────────────────────────────────

class _SongInfo extends StatelessWidget {
  final SongCard song;
  const _SongInfo({required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: GataColors.dusk,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Now Playing',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          song.title,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          song.artist,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: GataColors.roseLight,
          ),
        ),
        const SizedBox(height: 8),
        // Swipe hint
        Row(
          children: [
            Icon(Icons.swipe_vertical_rounded,
                size: 16, color: GataColors.textMuted),
            const SizedBox(width: 6),
            Text(
              'Swipe up for next',
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: GataColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Action buttons (right side) ────────────────────────────

class _ActionButtons extends StatefulWidget {
  final SongCard? song;
  const _ActionButtons({required this.song});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _actionBtn(
          icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: _liked ? GataColors.rose : Colors.white,
          onTap: () {
            Haptic.heavy();
            setState(() => _liked = !_liked);
          },
        ),
        const SizedBox(height: 20),
        _actionBtn(
          icon: Icons.share_rounded,
          color: Colors.white,
          onTap: () => Haptic.light(),
        ),
        const SizedBox(height: 20),
        // Spinning disc animation
        _SpinningDisc(),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: GataColors.surfaceFloat.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// ── Spinning disc (music indicator) ────────────────────────

class _SpinningDisc extends StatefulWidget {
  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _anim,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: GataColors.dusk,
          border: Border.all(color: GataColors.surfaceFloat, width: 3),
        ),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ── Page indicator dots ────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _PageIndicator({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    // Show max 8 dots
    final showCount = total.clamp(0, 8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(showCount, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: 4,
          height: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? GataColors.rose : GataColors.textMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
