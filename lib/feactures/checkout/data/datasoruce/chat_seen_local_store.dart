import 'package:shared_preferences/shared_preferences.dart';

/// Marca de tiempo del último chat visto, usada para calcular no leídos.
class ChatSeenLocalStore {
  const ChatSeenLocalStore._();

  static String _key(String rentalId) => 'chat_seen_$rentalId';

  static Future<void> markSeen(String rentalId, DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(rentalId), at.toUtc().toIso8601String());
  }

  static Future<DateTime?> lastSeen(String rentalId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(rentalId));
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
