import 'package:shared_preferences/shared_preferences.dart';

/// Único punto de acceso a SharedPreferences de sesión; centraliza las keys.
class SessionPrefsStore {
  const SessionPrefsStore._();

  static const _kToken = 'jwt_token';
  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserRole = 'user_role';
  static const _kUserPhone = 'user_phone';
  static const _kUserIne = 'user_ine';
  static const _kIsPro = 'user_is_pro';
  static const _kDeviceId = 'device_id';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // --- Lectura ---
  static Future<String?> token() async => (await _prefs).getString(_kToken);

  static Future<String> userId() async =>
      (await _prefs).getString(_kUserId) ?? '';

  static Future<String> userName() async =>
      (await _prefs).getString(_kUserName) ?? '';

  static Future<String> userEmail() async =>
      (await _prefs).getString(_kUserEmail) ?? '';

  static Future<String> userRole() async =>
      (await _prefs).getString(_kUserRole) ?? '';

  static Future<bool> isPro() async => (await _prefs).getBool(_kIsPro) ?? false;

  static Future<String?> deviceId() async =>
      (await _prefs).getString(_kDeviceId);

  // --- Escritura ---
  /// Persiste el perfil de sesión; cada capa pasa solo los campos que conoce.
  static Future<void> saveSession({
    required String token,
    required String id,
    required String name,
    required String email,
    required String role,
    bool? isPro,
    String? phone,
    String? ine,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, id);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserEmail, email);
    await prefs.setString(_kUserRole, role);
    if (isPro != null) await prefs.setBool(_kIsPro, isPro);
    if (phone != null) await prefs.setString(_kUserPhone, phone);
    if (ine != null) await prefs.setString(_kUserIne, ine);
  }

  static Future<void> setIsPro(bool value) async =>
      (await _prefs).setBool(_kIsPro, value);

  static Future<void> saveDeviceId(String id) async =>
      (await _prefs).setString(_kDeviceId, id);

  /// Borra toda la sesión plana (logout / cierre por inactividad).
  static Future<void> clear() async => (await _prefs).clear();
}
