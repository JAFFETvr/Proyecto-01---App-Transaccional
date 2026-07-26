import 'package:shared_preferences/shared_preferences.dart';

/// Almacén local (SharedPreferences) de la marca de tiempo en que cada chat de
/// renta fue visto por última vez. Vive en la capa de datos para que el
/// provider de chat no hable directamente con `SharedPreferences`; el punto
/// rojo de "mensajes sin leer" se calcula comparando contra este valor.
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
