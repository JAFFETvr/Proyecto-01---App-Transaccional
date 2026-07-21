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

  static Future<void> saveToken(String token) =>
      _storage.write(key: _kToken, value: token);

  static Future<String?> readToken() => _storage.read(key: _kToken);

  static Future<void> saveLastActive(DateTime time) =>
      _storage.write(key: _kLastActiveAt, value: time.toIso8601String());

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
