import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Solicita autenticación biométrica (huella dactilar, Face ID o PIN/Patrón de respaldo).
  /// Retorna `true` si la autenticación es exitosa, o si el dispositivo no soporta biometría (para permitir pruebas).
  /// Retorna `false` si el usuario cancela o la autenticación falla.
  static Future<bool> authenticateSignature() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Dispositivo sin soporte de biometría/bloqueo local (ej. emulador sin configurar)
        // Permitimos continuar para no bloquear las pruebas.
        return true;
      }

      return await _auth.authenticate(
        localizedReason: 'Por favor, autentícate para firmar digitalmente el contrato.',
        options: const AuthenticationOptions(
          biometricOnly: false, // Permite PIN, patrón o contraseña del celular si no hay biometría enrolada
          stickyAuth: true,     // Mantiene la sesión de autenticación si la app va a segundo plano temporalmente
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
