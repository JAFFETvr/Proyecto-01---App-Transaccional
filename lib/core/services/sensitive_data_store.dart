import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento encriptado para los datos sensibles del perfil del
/// usuario (Android: EncryptedSharedPreferences respaldado por el
/// Keystore; iOS: Keychain).
///
/// Se define como un almacén independiente del token de sesión
/// ([SecureSessionStore]) porque conceptualmente protege un dato distinto:
/// información personal identificable (PII) del usuario, no credenciales
/// de autenticación. Se puede borrar de forma remota vía FCM sin afectar
/// la sesión si así se requiriera.
class SensitiveDataStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kName = 'sensitive_name';
  static const _kEmail = 'sensitive_email';
  static const _kPhone = 'sensitive_phone';
  static const _kIne = 'sensitive_ine';

  static Future<void> saveAll({
    required String name,
    required String email,
    required String phone,
    required String ine,
  }) async {
    await _storage.write(key: _kName, value: name);
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPhone, value: phone);
    await _storage.write(key: _kIne, value: ine);
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
