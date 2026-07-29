import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacén encriptado de PII, separado del token: borrable vía FCM sin afectar la sesión.
class SensitiveDataStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kName = 'sensitive_name';
  static const _kEmail = 'sensitive_email';
  static const _kPhone = 'sensitive_phone';
  static const _kIne = 'sensitive_ine';

  // Ver SecureSessionStore._writeResilient: mismo workaround del bug -25299 de Keychain.
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

  static Future<void> saveAll({
    required String name,
    required String email,
    required String phone,
    required String ine,
  }) async {
    await _writeResilient(_kName, name);
    await _writeResilient(_kEmail, email);
    await _writeResilient(_kPhone, phone);
    await _writeResilient(_kIne, ine);
  }

  static Future<String?> readName() => _storage.read(key: _kName);
  static Future<String?> readEmail() => _storage.read(key: _kEmail);
  static Future<String?> readPhone() => _storage.read(key: _kPhone);
  static Future<String?> readIne() => _storage.read(key: _kIne);

  static Future<Map<String, String?>> readAll() async {
    return {
      'name': await readName(),
      'email': await readEmail(),
      'phone': await readPhone(),
      'ine': await readIne(),
    };
  }

  /// Borra únicamente los 4 campos sensibles, dejando intacto lo demás
  /// (token, preferencias). Es lo que dispara la notificación de FCM.
  static Future<void> wipe() async {
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPhone);
    await _storage.delete(key: _kIne);
  }
}
