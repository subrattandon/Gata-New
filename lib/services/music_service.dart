import '../models/models.dart';

/// Maps moods to curated YouTube song lists for the music reels.
class MusicService {
  static const Map<String, List<SongCard>> moodSongs = {
    'Loved': [
      SongCard(youtubeId: 'rtOvBOTyX00', title: 'Thinking Out Loud', artist: 'Ed Sheeran', mood: 'Loved'),
      SongCard(youtubeId: 'lp-EO5I60KA', title: 'All of Me', artist: 'John Legend', mood: 'Loved'),
      SongCard(youtubeId: '450p7goxZqg', title: 'Just the Way You Are', artist: 'Bruno Mars', mood: 'Loved'),
      SongCard(youtubeId: 'bo_efYhYU2A', title: 'Lover', artist: 'Taylor Swift', mood: 'Loved'),
      SongCard(youtubeId: '09R8_2nJtjg', title: 'Sugar', artist: 'Maroon 5', mood: 'Loved'),
      SongCard(youtubeId: 'nSDgHBxUbVQ', title: 'Perfect Duet', artist: 'Ed Sheeran ft. Beyoncé', mood: 'Loved'),
      SongCard(youtubeId: '2Vv-BfVoq4g', title: 'Perfect', artist: 'Ed Sheeran', mood: 'Loved'),
      SongCard(youtubeId: 'QDYfEBY9NM4', title: 'Let Me Love You', artist: 'DJ Snake ft. Justin Bieber', mood: 'Loved'),
    ],
    'Happy': [
      SongCard(youtubeId: 'ZbZSe6N_BXs', title: 'Happy', artist: 'Pharrell Williams', mood: 'Happy'),
      SongCard(youtubeId: 'ru0K8uYEZWw', title: 'Can\'t Stop the Feeling!', artist: 'Justin Timberlake', mood: 'Happy'),
      SongCard(youtubeId: 'OPf0YbXqDm0', title: 'Uptown Funk', artist: 'Mark Ronson ft. Bruno Mars', mood: 'Happy'),
      SongCard(youtubeId: 'fRh_vgS2dFE', title: 'Sorry', artist: 'Justin Bieber', mood: 'Happy'),
      SongCard(youtubeId: 'nfWlot6h_JM', title: 'Shake It Off', artist: 'Taylor Swift', mood: 'Happy'),
      SongCard(youtubeId: 'CevxZvSJLk8', title: 'Roar', artist: 'Katy Perry', mood: 'Happy'),
      SongCard(youtubeId: 'JGwWNGJdvx8', title: 'Shape of You', artist: 'Ed Sheeran', mood: 'Happy'),
      SongCard(youtubeId: 'hT_nvWreIhg', title: 'Counting Stars', artist: 'OneRepublic', mood: 'Happy'),
    ],
    'Calm': [
      SongCard(youtubeId: 'lTRiuFIWV54', title: 'Let Her Go', artist: 'Passenger', mood: 'Calm'),
      SongCard(youtubeId: 'pB-5XG-DbAA', title: 'Say You Won\'t Let Go', artist: 'James Arthur', mood: 'Calm'),
      SongCard(youtubeId: 'RBumgq5yVrA', title: 'Photograph', artist: 'Ed Sheeran', mood: 'Calm'),
      SongCard(youtubeId: 'k4V3Mo61fJM', title: 'Love Me Like You Do', artist: 'Ellie Goulding', mood: 'Calm'),
      SongCard(youtubeId: '60ItHLz5WEA', title: 'All I Want', artist: 'Kodaline', mood: 'Calm'),
      SongCard(youtubeId: 'YQHsXMglC9A', title: 'Hello', artist: 'Adele', mood: 'Calm'),
      SongCard(youtubeId: '1cCB0pM1yX8', title: 'Chasing Cars', artist: 'Snow Patrol', mood: 'Calm'),
      SongCard(youtubeId: 'hLQl3WQQoQ0', title: 'Someone Like You', artist: 'Adele', mood: 'Calm'),
    ],
    'Tired': [
      SongCard(youtubeId: '3AtDnEC4zak', title: 'Faded', artist: 'Alan Walker', mood: 'Tired'),
      SongCard(youtubeId: 'pUjE9H8QlA4', title: 'Night Changes', artist: 'One Direction', mood: 'Tired'),
      SongCard(youtubeId: 'RgKAFK5djSk', title: 'See You Again', artist: 'Wiz Khalifa ft. Charlie Puth', mood: 'Tired'),
      SongCard(youtubeId: 'nVjsGKrE6E8', title: 'Heather', artist: 'Conan Gray', mood: 'Tired'),
      SongCard(youtubeId: 'HQ7mX_BGbSE', title: 'Falling', artist: 'Harry Styles', mood: 'Tired'),
      SongCard(youtubeId: '60ItHLz5WEA', title: 'All I Want', artist: 'Kodaline', mood: 'Tired'),
      SongCard(youtubeId: 'izGwDsrQ1eQ', title: 'Lucid Dreams', artist: 'Juice WRLD', mood: 'Tired'),
      SongCard(youtubeId: 'bx1Bh8ZvH84', title: 'Sweater Weather', artist: 'The Neighbourhood', mood: 'Tired'),
    ],
    'Missing you': [
      SongCard(youtubeId: 'RgKAFK5djSk', title: 'See You Again', artist: 'Wiz Khalifa ft. Charlie Puth', mood: 'Missing you'),
      SongCard(youtubeId: 'nVjsGKrE6E8', title: 'Heather', artist: 'Conan Gray', mood: 'Missing you'),
      SongCard(youtubeId: 'lp-EO5I60KA', title: 'All of Me', artist: 'John Legend', mood: 'Missing you'),
      SongCard(youtubeId: 'pB-5XG-DbAA', title: 'Say You Won\'t Let Go', artist: 'James Arthur', mood: 'Missing you'),
      SongCard(youtubeId: 'hLQl3WQQoQ0', title: 'Someone Like You', artist: 'Adele', mood: 'Missing you'),
      SongCard(youtubeId: 'SpSMoBp8awM', title: 'Photograph', artist: 'Ed Sheeran', mood: 'Missing you'),
      SongCard(youtubeId: 'YQHsXMglC9A', title: 'Hello', artist: 'Adele', mood: 'Missing you'),
      SongCard(youtubeId: '3JZ_D3ELwOQ', title: 'Someone You Loved', artist: 'Lewis Capaldi', mood: 'Missing you'),
    ],
    'Low': [
      SongCard(youtubeId: '3JZ_D3ELwOQ', title: 'Someone You Loved', artist: 'Lewis Capaldi', mood: 'Low'),
      SongCard(youtubeId: 'YQHsXMglC9A', title: 'Hello', artist: 'Adele', mood: 'Low'),
      SongCard(youtubeId: 'hLQl3WQQoQ0', title: 'Someone Like You', artist: 'Adele', mood: 'Low'),
      SongCard(youtubeId: 'HQ7mX_BGbSE', title: 'Falling', artist: 'Harry Styles', mood: 'Low'),
      SongCard(youtubeId: 'izGwDsrQ1eQ', title: 'Lucid Dreams', artist: 'Juice WRLD', mood: 'Low'),
      SongCard(youtubeId: '60ItHLz5WEA', title: 'All I Want', artist: 'Kodaline', mood: 'Low'),
      SongCard(youtubeId: '3AtDnEC4zak', title: 'Faded', artist: 'Alan Walker', mood: 'Low'),
      SongCard(youtubeId: 'nVjsGKrE6E8', title: 'Heather', artist: 'Conan Gray', mood: 'Low'),
    ],
    'Stressed': [
      SongCard(youtubeId: '1cCB0pM1yX8', title: 'Chasing Cars', artist: 'Snow Patrol', mood: 'Stressed'),
      SongCard(youtubeId: 'lTRiuFIWV54', title: 'Let Her Go', artist: 'Passenger', mood: 'Stressed'),
      SongCard(youtubeId: 'k4V3Mo61fJM', title: 'Love Me Like You Do', artist: 'Ellie Goulding', mood: 'Stressed'),
      SongCard(youtubeId: 'pB-5XG-DbAA', title: 'Say You Won\'t Let Go', artist: 'James Arthur', mood: 'Stressed'),
      SongCard(youtubeId: 'RBumgq5yVrA', title: 'Photograph', artist: 'Ed Sheeran', mood: 'Stressed'),
      SongCard(youtubeId: '3AtDnEC4zak', title: 'Faded', artist: 'Alan Walker', mood: 'Stressed'),
      SongCard(youtubeId: 'bx1Bh8ZvH84', title: 'Sweater Weather', artist: 'The Neighbourhood', mood: 'Stressed'),
      SongCard(youtubeId: 'pUjE9H8QlA4', title: 'Night Changes', artist: 'One Direction', mood: 'Stressed'),
    ],
    'Unwell': [
      SongCard(youtubeId: 'pB-5XG-DbAA', title: 'Say You Won\'t Let Go', artist: 'James Arthur', mood: 'Unwell'),
      SongCard(youtubeId: '1cCB0pM1yX8', title: 'Chasing Cars', artist: 'Snow Patrol', mood: 'Unwell'),
      SongCard(youtubeId: 'lTRiuFIWV54', title: 'Let Her Go', artist: 'Passenger', mood: 'Unwell'),
      SongCard(youtubeId: '2Vv-BfVoq4g', title: 'Perfect', artist: 'Ed Sheeran', mood: 'Unwell'),
      SongCard(youtubeId: '60ItHLz5WEA', title: 'All I Want', artist: 'Kodaline', mood: 'Unwell'),
      SongCard(youtubeId: 'hLQl3WQQoQ0', title: 'Someone Like You', artist: 'Adele', mood: 'Unwell'),
      SongCard(youtubeId: 'HQ7mX_BGbSE', title: 'Falling', artist: 'Harry Styles', mood: 'Unwell'),
      SongCard(youtubeId: 'nVjsGKrE6E8', title: 'Heather', artist: 'Conan Gray', mood: 'Unwell'),
    ],
  };

  /// Returns songs for a given mood label. Falls back to 'Calm' if not found.
  static List<SongCard> songsForMood(String mood) {
    return moodSongs[mood] ?? moodSongs['Calm']!;
  }

  /// Returns all available mood labels.
  static List<String> get availableMoods => moodSongs.keys.toList();
}
