import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this._store) {
    _loadProfile();
  }

  final LocalStore _store;
  final _uuid = const Uuid();

  // ── local-only keys (profile, set once at onboarding) ──
  static const _kMe = 'me';
  static const _kHer = 'her';
  static const _kHerEmail = 'her_email';
  static const _kAnniversary = 'anniversary';
  static const _kPaired = 'paired';
  static const _kInvite = 'invite_code';

  // ── couple ─────────────────────────────────────────────
  AppUser? me;
  AppUser? partner;
  String herEmail = '';
  DateTime? anniversary;
  bool partnerPaired = false;
  String inviteCode = '';

  bool get signedIn => me != null && partner != null;
  bool get awaitingPartner => signedIn && !partnerPaired;

  Sender activeSender = Sender.me;

  // ── live data (driven by Firestore streams) ─────────────
  final List<Message> messages = [];
  final List<Post> posts = [];
  final List<BucketItem> bucket = [];
  MoodEntry? moodMe;
  MoodEntry? moodHer;
  String spaceNote = '';

  bool _loaded = false;
  bool get loaded => _loaded;

  // ── Firestore subscriptions ────────────────────────────
  StreamSubscription? _msgSub;
  StreamSubscription? _postSub;
  StreamSubscription? _roomSub;
  bool _firestoreActive = false;

  // ── load profile from local store ─────────────────────
  void _loadProfile() {
    final meJson = _store.readMap(_kMe);
    final herJson = _store.readMap(_kHer);
    if (meJson != null) me = AppUser.fromJson(meJson);
    if (herJson != null) partner = AppUser.fromJson(herJson);
    herEmail = _store.readString(_kHerEmail) ?? '';
    partnerPaired = _store.readString(_kPaired) == '1';
    inviteCode = _store.readString(_kInvite) ?? '';
    final ann = _store.readString(_kAnniversary);
    if (ann != null && ann.isNotEmpty) anniversary = DateTime.tryParse(ann);
    _loaded = true;
    notifyListeners();
  }

  // ── start Firestore sync (called once after Firebase auth confirms) ──
  void startFirestoreSync() {
    if (_firestoreActive) return;
    _firestoreActive = true;

    _msgSub = FirestoreService.watchMessages().listen((msgs) {
      messages
        ..clear()
        ..addAll(msgs);
      notifyListeners();
    }, onError: (_) {});

    _postSub = FirestoreService.watchPosts().listen((ps) {
      posts
        ..clear()
        ..addAll(ps);
      notifyListeners();
    }, onError: (_) {});

    _roomSub = FirestoreService.watchRoom().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      spaceNote = data['spaceNote'] as String? ?? '';

      final rawBucket = data['bucket'] as List? ?? [];
      bucket
        ..clear()
        ..addAll(rawBucket
            .cast<Map<String, dynamic>>()
            .map(BucketItem.fromJson));

      final mm = data['${Sender.me.id}Mood'] as Map<String, dynamic>?;
      final mh = data['${Sender.her.id}Mood'] as Map<String, dynamic>?;
      if (mm != null) moodMe = MoodEntry.fromJson(mm);
      if (mh != null) moodHer = MoodEntry.fromJson(mh);

      // Sync anniversary from cloud if not set locally.
      if (anniversary == null && data['anniversary'] != null) {
        anniversary =
            (data['anniversary'] as Timestamp).toDate();
      }

      // Sync partner profile if we don't have it yet.
      final profiles =
          data['profiles'] as Map<String, dynamic>?;
      if (profiles != null && partner == null) {
        final herData = profiles[herEmail] as Map<String, dynamic>?;
        if (herData != null) {
          partner = AppUser.fromJson(herData);
          notifyListeners();
        }
      }

      notifyListeners();
    }, onError: (_) {});
  }

  void _cancelFirestoreSync() {
    _msgSub?.cancel();
    _postSub?.cancel();
    _roomSub?.cancel();
    _msgSub = _postSub = _roomSub = null;
    _firestoreActive = false;
  }

  // ── onboarding sign-in ─────────────────────────────────
  Future<void> signIn({
    required String myName,
    required String myEmail,
    required String myEmoji,
    required String herName,
    required String herEmoji,
    required String herEmailAddr,
    required DateTime anniversaryDate,
  }) async {
    me = AppUser(name: myName, emoji: myEmoji, email: myEmail);
    partner = AppUser(name: herName, emoji: herEmoji, email: herEmailAddr);
    herEmail = herEmailAddr;
    anniversary = anniversaryDate;
    if (inviteCode.isEmpty) inviteCode = _genInviteCode();

    await _store.writeMap(_kMe, me!.toJson());
    await _store.writeMap(_kHer, partner!.toJson());
    await _store.writeString(_kHerEmail, herEmailAddr);
    await _store.writeString(_kInvite, inviteCode);
    await _store.writeString(_kAnniversary, anniversaryDate.toIso8601String());

    // Write room + profiles to Firestore so her phone can read it.
    await FirestoreService.initRoom(
        myEmail, herEmailAddr, myName, herName, anniversaryDate);
    // Write my profile so she can see my name/emoji.
    await FirestoreService.setProfile(myEmail, me!);

    notifyListeners();
  }

  String get inviteLink => 'https://gata.app/join/$inviteCode';

  String _genInviteCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    var n = _uuid.v4().hashCode.abs();
    final buf = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buf.write(chars[n % chars.length]);
      n = (n ~/ chars.length) + (i + 1) * 7919;
    }
    return buf.toString();
  }

  Future<void> markPaired() async {
    partnerPaired = true;
    await _store.writeString(_kPaired, '1');
    notifyListeners();
  }

  Future<void> enterPreview() => markPaired();

  Future<void> signOut() async {
    _cancelFirestoreSync();
    await _store.clear();
    me = null;
    partner = null;
    herEmail = '';
    partnerPaired = false;
    inviteCode = '';
    anniversary = null;
    messages.clear();
    posts.clear();
    bucket.clear();
    moodMe = null;
    moodHer = null;
    spaceNote = '';
    _loaded = false;
    notifyListeners();
  }

  // ── sender toggle ──────────────────────────────────────
  void setActiveSender(Sender s) {
    activeSender = s;
    notifyListeners();
  }

  // ── chat ───────────────────────────────────────────────
  Future<void> sendMessage(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final msg = Message(
      id: _uuid.v4(),
      text: t,
      sender: activeSender,
      time: DateTime.now(),
    );
    // Optimistic: show immediately; stream will dedup on arrival.
    messages.insert(0, msg);
    notifyListeners();
    await FirestoreService.sendMessage(msg);
  }

  Future<void> reactToMessage(String id, String? emoji) async {
    final i = messages.indexWhere((m) => m.id == id);
    if (i == -1) return;
    messages[i] = messages[i].copyWith(reaction: emoji);
    notifyListeners();
    await FirestoreService.reactToMessage(id, emoji);
  }

  // ── posts ──────────────────────────────────────────────
  Future<void> addPost(String caption, String emoji,
      {String? imagePath}) async {
    final post = Post(
      id: _uuid.v4(),
      caption: caption.trim(),
      emoji: emoji,
      imagePath: imagePath,
      author: activeSender,
      time: DateTime.now(),
    );
    posts.insert(0, post);
    notifyListeners();
    await FirestoreService.addPost(post);
  }

  List<Post> get photoPosts => posts.where((p) => p.hasPhoto).toList();

  Future<void> toggleLove(String id) async {
    final i = posts.indexWhere((p) => p.id == id);
    if (i == -1) return;
    posts[i].loved = !posts[i].loved;
    notifyListeners();
    await FirestoreService.toggleLove(id, posts[i].loved);
  }

  // ── shared space ───────────────────────────────────────
  int get daysTogether => anniversary == null
      ? 0
      : DateTime.now().difference(anniversary!).inDays;

  Future<void> addBucketItem(String title) async {
    if (title.trim().isEmpty) return;
    bucket.add(BucketItem(id: _uuid.v4(), title: title.trim()));
    notifyListeners();
    await FirestoreService.setBucket(bucket);
  }

  Future<void> toggleBucket(String id) async {
    final i = bucket.indexWhere((b) => b.id == id);
    if (i == -1) return;
    bucket[i].done = !bucket[i].done;
    notifyListeners();
    await FirestoreService.setBucket(bucket);
  }

  Future<void> removeBucket(String id) async {
    bucket.removeWhere((b) => b.id == id);
    notifyListeners();
    await FirestoreService.setBucket(bucket);
  }

  Future<void> setSpaceNote(String note) async {
    spaceNote = note;
    notifyListeners();
    await FirestoreService.setNote(note);
  }

  // ── mood ───────────────────────────────────────────────
  Future<void> setMood(Sender who, String emoji, String label) async {
    final entry = MoodEntry(emoji: emoji, label: label, time: DateTime.now());
    if (who == Sender.me) {
      moodMe = entry;
    } else {
      moodHer = entry;
    }
    notifyListeners();
    await FirestoreService.setMood(who, entry);
  }

  // ── helpers ────────────────────────────────────────────
  AppUser userFor(Sender s) =>
      s == Sender.me ? (me ?? _fallbackMe) : (partner ?? _fallbackHer);

  static const _fallbackMe = AppUser(name: 'Me', emoji: '💖');
  static const _fallbackHer = AppUser(name: 'Her', emoji: '🌷');
}
