import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/haptic_service.dart';
import '../../services/photo_service.dart';
import '../../state/app_state.dart';
import '../../theme/gata_theme.dart';
import '../../widgets/feed_post_card.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  int _tab = 0; // 0 = feed, 1 = gallery

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Container(
      decoration: const BoxDecoration(gradient: GataColors.screen),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Our Moments'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _tabs(),
            ),
          ),
        ),
        body: Stack(
          children: [
            _tab == 0 ? _feed(app) : _gallery(app),
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 8,
              child: FloatingActionButton.extended(
                heroTag: 'posts_fab',
                backgroundColor: GataColors.rose,
                elevation: 6,
                onPressed: () {
                  Haptic.heavy();
                  _composer(context, app);
                },
                icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
                label: Text('Share',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          _tabBtn('Feed', Icons.dynamic_feed_rounded, 0),
          _tabBtn('Gallery', Icons.grid_view_rounded, 1),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, IconData icon, int index) {
    final on = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () { Haptic.select(); setState(() => _tab = index); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: on ? GataColors.blush : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17, color: on ? Colors.white : GataColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: on ? Colors.white : GataColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // ── feed ───────────────────────────────────────────────
  Widget _feed(AppState app) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 80;
    if (app.posts.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(0, 16, 0, bottomPad),
        children: const [DemoFlipCard()],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPad),
      itemCount: app.posts.length,
      itemBuilder: (_, i) {
        final post = app.posts[i];
        return FeedPostCard(
          key: ValueKey(post.id),
          post: post,
          author: app.userFor(post.author),
          onLove: (id, intensity) => app.sendLove(id, intensity),
          onCompliment: (text) => app.sendCompliment(post.id, text),
        );
      },
    );
  }

  // ── gallery ────────────────────────────────────────────
  Widget _gallery(AppState app) {
    final photos = app.photoPosts;
    if (photos.isEmpty) {
      return _empty('🖼️', 'No photos yet.\nAdd a couple photo 💞');
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(14, 8, 14, MediaQuery.of(context).padding.bottom + 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final p = photos[i];
        return GestureDetector(
          onTap: () { Haptic.light(); _openViewer(context, photos, i); },
          child: Hero(
            tag: p.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(p.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: GataColors.lavenderLight,
                  child: const Icon(Icons.broken_image_rounded,
                      color: GataColors.textMuted),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, List<Post> photos, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(photos: photos, start: index, app: context.read<AppState>()),
    ));
  }

  Widget _empty(String emoji, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: GataColors.textSecondary)),
          ],
        ),
      );

  // ── composer ───────────────────────────────────────────
  void _composer(BuildContext context, AppState app) {
    final caption = TextEditingController();
    String emoji = '🌸';
    String? photoPath;
    bool isPrivate = false;
    const choices = ['🌸', '🌅', '🍰', '🎁', '🏖️', '🌙', '🐾', '☕', '💐', '🎶'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Future<void> pick(bool camera) async {
            final path = camera
                ? await PhotoService.pickFromCamera()
                : await PhotoService.pickFromGallery();
            if (path != null) setSheet(() => photoPath = path);
          }

          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: GataColors.surfaceFloat,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: GataColors.rose.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Share a moment',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: GataColors.textPrimary)),
                  const SizedBox(height: 16),
                  // Photo area
                  if (photoPath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(photoPath!),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setSheet(() => photoPath = null),
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _pickBtn(
                              Icons.photo_library_rounded, 'Gallery',
                              () => pick(false)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _pickBtn(
                              Icons.photo_camera_rounded, 'Camera',
                              () => pick(true)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Sticker row only matters when there's no photo
                  if (photoPath == null) ...[
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: choices.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final on = choices[i] == emoji;
                          return GestureDetector(
                            onTap: () => setSheet(() => emoji = choices[i]),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: on ? GataColors.dusk : null,
                                color: on ? null : GataColors.surfaceFloat,
                              ),
                              child: Center(
                                  child: Text(choices[i],
                                      style: const TextStyle(fontSize: 22))),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: caption,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                        hintText: 'Write a little something…'),
                  ),
                  const SizedBox(height: 14),
                  // Private toggle
                  GestureDetector(
                    onTap: () {
                      Haptic.select();
                      setSheet(() => isPrivate = !isPrivate);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPrivate
                            ? GataColors.rose.withValues(alpha: 0.12)
                            : GataColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPrivate
                              ? GataColors.rose.withValues(alpha: 0.4)
                              : GataColors.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrivate ? Icons.lock_rounded : Icons.lock_open_rounded,
                            size: 16,
                            color: isPrivate ? GataColors.rose : GataColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPrivate ? 'Private moment' : 'Make private',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isPrivate ? GataColors.rose : GataColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (caption.text.trim().isEmpty && photoPath == null) {
                          return;
                        }
                        app.addPost(caption.text, emoji,
                            imagePath: photoPath, isPrivate: isPrivate);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Post 💕'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pickBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: GataColors.surfaceFloat,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GataColors.rose.withValues(alpha: 0.25), width: 1.4),
        ),
        child: Column(
          children: [
            Icon(icon, color: GataColors.roseDark, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GataColors.roseDark)),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.app});
  final Post post;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final author = app.userFor(post.author);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: GataColors.surfaceFloat,
        borderRadius: BorderRadius.circular(26),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, gradient: GataColors.dusk),
                  child: Center(
                      child: Text(author.emoji,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author.name,
                        style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: GataColors.textPrimary)),
                    Text(DateFormat('MMM d • h:mm a').format(post.time),
                        style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: GataColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          // Visual: real photo if present, else the sticker gradient.
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: post.hasPhoto
                  ? Image.file(
                      File(post.imagePath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _stickerBox(post.emoji),
                    )
                  : _stickerBox(post.emoji),
            ),
          ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(post.caption,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: GataColors.textPrimary)),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () => app.toggleLove(post.id),
                icon: Icon(
                  post.loved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.loved ? GataColors.rose : GataColors.textMuted,
                ),
              ),
              if (post.loved)
                Text('You love this',
                    style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: GataColors.roseDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stickerBox(String emoji) => Container(
        height: 180,
        decoration: const BoxDecoration(gradient: GataColors.lavenderGlow),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 72))),
      );
}

/// Swipeable fullscreen photo viewer with pinch-zoom.
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer(
      {required this.photos, required this.start, required this.app});
  final List<Post> photos;
  final int start;
  final AppState app;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pc = PageController(initialPage: widget.start);
  late int _i = widget.start;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[_i];
    final author = widget.app.userFor(p.author);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${author.name} • ${DateFormat('MMM d, y').format(p.time)}',
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _i = i),
        itemBuilder: (_, i) {
          final photo = widget.photos[i];
          return Center(
            child: Hero(
              tag: photo.id,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.file(File(photo.imagePath!), fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.photos[_i].caption.isEmpty
          ? null
          : Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              width: double.infinity,
              child: Text(widget.photos[_i].caption,
                  style: GoogleFonts.nunito(
                      color: GataColors.surfaceFloat,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
    );
  }
}
