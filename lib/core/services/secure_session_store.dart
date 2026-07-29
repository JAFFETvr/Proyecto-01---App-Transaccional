import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén encriptado de sesión (token + última actividad): Keystore/Keychain.
class SecureSessionStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'secure_jwt_token';
  static const _kLastActiveAt = 'secure_last_active_at';

  // Workaround: Keychain iOS a veces da -25299 en key huérfana; borra y reintenta.
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
