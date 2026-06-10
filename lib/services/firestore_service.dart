import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// All Firestore ops live here — single coupling point between the data layer
/// and the database. Everything is scoped to the shared "couple" document.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // One room for exactly one couple.
  static const _roomId = 'our-space';
  static DocumentReference get _room =>
      _db.collection('rooms').doc(_roomId);

  // ── sub-collections ──────────────────────────────────────
  static CollectionReference get _msgs =>
      _room.collection('messages');
  static CollectionReference get _posts =>
      _room.collection('posts');

  // ── room doc fields (mood, note, bucket) ────────────────
  static Future<void> setProfile(String email, AppUser user) =>
      _room.set({
        'profiles': {email: user.toJson()},
      }, SetOptions(merge: true));

  static Future<void> initRoom(String myEmail, String herEmail,
      String myName, String herName, DateTime anniversary) async {
    await _room.set({
      'members': [myEmail, herEmail],
      'myName': myName,
      'herName': herName,
      'anniversary': Timestamp.fromDate(anniversary),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getRoom() async {
    final snap = await _room.get();
    return snap.exists ? snap.data() as Map<String, dynamic> : null;
  }

  static Stream<DocumentSnapshot> watchRoom() => _room.snapshots();

  // ── messages ─────────────────────────────────────────────
  static Stream<List<Message>> watchMessages() {
    return _msgs
        .orderBy('time', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Message.fromJson({
                  'id': d.id,
                  ...d.data() as Map<String, dynamic>,
                  'time': (d['time'] as Timestamp).toDate().toIso8601String(),
                }))
            .toList());
  }

  static Future<void> sendMessage(Message m) => _msgs.doc(m.id).set({
        'text': m.text,
        'sender': m.sender.id,
        'time': Timestamp.fromDate(m.time),
        'reaction': m.reaction,
      });

  static Future<void> reactToMessage(String id, String? emoji) =>
      _msgs.doc(id).update({'reaction': emoji});

  /// Called when she opens the chat — marks her last-seen timestamp.
  static Future<void> markSeen(String viewerEmail) =>
      _room.set({'lastSeen_$viewerEmail': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

  /// Updates a single message's status (sent → delivered → seen).
  static Future<void> updateMsgStatus(String id, String status) =>
      _msgs.doc(id).update({'status': status});

  /// Stream of her last-seen timestamp (used to flip ticks to pink).
  static Stream<DateTime?> watchLastSeen(String herEmail) =>
      _room.snapshots().map((snap) {
        if (!snap.exists) return null;
        final data = snap.data() as Map<String, dynamic>;
        final ts = data['lastSeen_$herEmail'];
        if (ts == null) return null;
        return (ts as Timestamp).toDate();
      });

  // ── posts ────────────────────────────────────────────────
  static Stream<List<Post>> watchPosts() {
    return _posts
        .orderBy('time', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Post.fromJson({
                  'id': d.id,
                  ...d.data() as Map<String, dynamic>,
                  'time': (d['time'] as Timestamp).toDate().toIso8601String(),
                }))
            .toList());
  }

  static Future<void> addPost(Post p) => _posts.doc(p.id).set({
        'caption': p.caption,
        'emoji': p.emoji,
        'imagePath': p.imagePath,
        'author': p.author.id,
        'time': Timestamp.fromDate(p.time),
        'loved': p.loved,
        'loveIntensity': p.loveIntensity,
        'loveSender': p.loveSender?.id,
        'loveTime': p.loveTime != null ? Timestamp.fromDate(p.loveTime!) : null,
        'isPrivate': p.isPrivate,
      });

  static Future<void> toggleLove(String id, bool loved) =>
      _posts.doc(id).update({'loved': loved});

  static Future<void> setLove(String id, double intensity, String senderId) =>
      _posts.doc(id).update({
        'loved': true,
        'loveIntensity': intensity,
        'loveSender': senderId,
        'loveTime': FieldValue.serverTimestamp(),
      });

  // ── compliments ────────────────────────────────────────────
  static CollectionReference get _compliments => _room.collection('compliments');

  static Future<void> sendCompliment(Compliment c) =>
      _compliments.doc(c.id).set(c.toJson()..['time'] = Timestamp.fromDate(c.time));

  static Stream<List<Compliment>> watchCompliments(String postId) {
    return _compliments
        .where('postId', isEqualTo: postId)
        .orderBy('time', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return Compliment.fromJson(d.id, {
                ...data,
                'time': (data['time'] as Timestamp).toDate().toIso8601String(),
              });
            }).toList());
  }

  // ── shared space: note, bucket, moods ───────────────────
  static Future<void> setNote(String note) =>
      _room.update({'spaceNote': note});

  static Future<void> setBucket(List<BucketItem> bucket) =>
      _room.update({'bucket': bucket.map((b) => b.toJson()).toList()});

  static Future<void> setMood(Sender who, MoodEntry entry) =>
      _room.update({
        '${who.id}Mood': entry.toJson(),
      });

  // ── tap to feel (touches) ──────────────────────────────────
  static CollectionReference get _touches => _room.collection('touches');

  static Future<void> sendTouch(TouchEvent t) =>
      _touches.doc(t.id).set({
        'sender': t.sender.id,
        'x': t.x,
        'y': t.y,
        'time': Timestamp.fromDate(t.time),
      });

  static Stream<List<TouchEvent>> watchTouches() {
    return _touches
        .orderBy('time', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs
            .map((d) {
              final data = d.data() as Map<String, dynamic>;
              return TouchEvent(
                id: d.id,
                sender: SenderX.fromId(data['sender']),
                x: (data['x'] as num).toDouble(),
                y: (data['y'] as num).toDouble(),
                time: (data['time'] as Timestamp).toDate(),
              );
            })
            .toList());
  }

  static Future<void> deleteTouch(String id) => _touches.doc(id).delete();

  // ── quick reactions ────────────────────────────────────────
  static CollectionReference get _reactions => _room.collection('reactions');

  static Future<void> sendReaction(QuickReaction r) =>
      _reactions.doc(r.id).set({
        'sender': r.sender.id,
        'type': r.type.name,
        'time': Timestamp.fromDate(r.time),
      });

  static Stream<List<QuickReaction>> watchReactions() {
    return _reactions
        .orderBy('time', descending: true)
        .limit(5)
        .snapshots()
        .map((s) => s.docs
            .map((d) {
              final data = d.data() as Map<String, dynamic>;
              return QuickReaction(
                id: d.id,
                sender: SenderX.fromId(data['sender']),
                type: ReactionType.values.firstWhere(
                    (r) => r.name == data['type'],
                    orElse: () => ReactionType.hug),
                time: (data['time'] as Timestamp).toDate(),
              );
            })
            .toList());
  }

  static Future<void> deleteReaction(String id) =>
      _reactions.doc(id).delete();
}
