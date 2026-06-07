import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin persistence wrapper over shared_preferences.
///
/// Everything is stored as JSON strings keyed by collection name. This is the
/// single seam where Firebase swaps in later: replace these read/write calls
/// with Firestore streams and the rest of the app is unchanged.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  List<Map<String, dynamic>> readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));

  Map<String, dynamic>? readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
  Future<void> clear() => _prefs.clear();
}
