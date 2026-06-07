/// Who sent a thing: me or my partner.
enum Sender { me, her }

extension SenderX on Sender {
  String get id => this == Sender.me ? 'me' : 'her';
  static Sender fromId(String v) => v == 'her' ? Sender.her : Sender.me;
  Sender get opposite => this == Sender.me ? Sender.her : Sender.me;
}

/// A person in the couple. For the local build there are exactly two.
class AppUser {
  final String name;
  final String emoji; // avatar stand-in until photos are wired
  final String email;

  const AppUser({required this.name, required this.emoji, this.email = ''});

  Map<String, dynamic> toJson() => {'name': name, 'emoji': emoji, 'email': email};
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        name: j['name'] ?? '',
        emoji: j['emoji'] ?? '💖',
        email: j['email'] ?? '',
      );
}

enum MsgStatus { sent, delivered, seen }

class Message {
  final String id;
  final String text;
  final Sender sender;
  final DateTime time;
  final String? reaction;
  final MsgStatus status;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    this.reaction,
    this.status = MsgStatus.sent,
  });

  Message copyWith({String? reaction, MsgStatus? status}) => Message(
        id: id,
        text: text,
        sender: sender,
        time: time,
        reaction: reaction ?? this.reaction,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.id,
        'time': time.toIso8601String(),
        'reaction': reaction,
        'status': status.name,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'],
        text: j['text'],
        sender: SenderX.fromId(j['sender']),
        time: DateTime.parse(j['time']),
        reaction: j['reaction'],
        status: MsgStatus.values.firstWhere(
          (s) => s.name == (j['status'] ?? 'sent'),
          orElse: () => MsgStatus.sent,
        ),
      );
}

class Post {
  final String id;
  final String caption;
  final String emoji; // sticker shown when there's no photo
  final String? imagePath; // local file path of the couple photo, nullable
  final Sender author;
  final DateTime time;
  bool loved;

  Post({
    required this.id,
    required this.caption,
    required this.emoji,
    this.imagePath,
    required this.author,
    required this.time,
    this.loved = false,
  });

  bool get hasPhoto => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'caption': caption,
        'emoji': emoji,
        'imagePath': imagePath,
        'author': author.id,
        'time': time.toIso8601String(),
        'loved': loved,
      };

  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'],
        caption: j['caption'],
        emoji: j['emoji'] ?? '🌸',
        imagePath: j['imagePath'],
        author: SenderX.fromId(j['author']),
        time: DateTime.parse(j['time']),
        loved: j['loved'] ?? false,
      );
}

class BucketItem {
  final String id;
  final String title;
  bool done;

  BucketItem({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory BucketItem.fromJson(Map<String, dynamic> j) =>
      BucketItem(id: j['id'], title: j['title'], done: j['done'] ?? false);
}

/// A mood entry for one person.
class MoodEntry {
  final String emoji;
  final String label;
  final DateTime time;

  const MoodEntry({required this.emoji, required this.label, required this.time});

  Map<String, dynamic> toJson() =>
      {'emoji': emoji, 'label': label, 'time': time.toIso8601String()};
  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        emoji: j['emoji'],
        label: j['label'],
        time: DateTime.parse(j['time']),
      );
}

/// Preset moods shown in the mood picker.
const kMoods = <(String, String)>[
  ('🥰', 'Loved'),
  ('😄', 'Happy'),
  ('😌', 'Calm'),
  ('🥱', 'Tired'),
  ('🥺', 'Missing you'),
  ('😔', 'Low'),
  ('😤', 'Stressed'),
  ('🤒', 'Unwell'),
];

/// Avatar emoji choices at sign-in.
const kAvatarChoices = ['💖', '🌷', '🦋', '🐻', '🌙', '⭐', '🍓', '🐱'];
