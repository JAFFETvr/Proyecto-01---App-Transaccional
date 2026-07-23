import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén encriptado de la sesión: token JWT y marca de tiempo de la
/// última interacción del usuario. En Android usa EncryptedSharedPreferences
/// (respaldado por el Keystore) y en iOS el Keychain.
class SecureSessionStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'secure_jwt_token';
  static const _kLastActiveAt = 'secure_last_active_at';

  // El Keychain de iOS a veces truena con "-25299 the specified item
  // already exists" al escribir una key que quedó huérfana de una
  // instalación/firma anterior (muy común reinstalando en debug). Se borra
  // la entrada y se reintenta una vez en vez de dejar la excepción sin
  // manejar — esto se llama en cada toque de pantalla (ver
  // InactivityWatcher), así que un fallo aquí no debe tronar la app.
  static Future<void> _writeResilient(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException {
      try {
        await _storage.delete(key: key);
        await _storage.write(key: key, value: value);
      } catch (_) {}
    } catch (_) {}
  }

  static Future<void> saveToken(String token) =>
      _writeResilient(_kToken, token);

  static Future<String?> readToken() => _storage.read(key: _kToken);

  static Future<void> saveLastActive(DateTime time) =>
      _writeResilient(_kLastActiveAt, time.toIso8601String());

  static Future<DateTime?> readLastActive() async {
    final raw = await _storage.read(key: _kLastActiveAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kLastActiveAt);
  }
}
