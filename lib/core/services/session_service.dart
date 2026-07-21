import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_navigator.dart';
import 'secure_session_store.dart';
import 'sensitive_data_store.dart';
import '../../feactures/auth/login/presentation/providers/login_provider.dart';
import '../../feactures/auth/login/presentation/screes/login_screen.dart';
import '../../feactures/auth/register/presentation/providers/register_provider.dart';
import '../../feactures/propietario/presentation/providers/tool_provider.dart';
import '../../feactures/checkout/presentation/providers/rental_provider.dart';

/// Cierra la sesión activa: limpia el estado en memoria, borra las
/// preferencias planas y regresa al login. Usado por servicios que no
/// tienen un BuildContext propio de pantalla (watchdog de inactividad,
/// handler de borrado remoto por FCM).
class SessionService {
  static Future<void> logoutForInactivity() => _closeSession(
        message: 'Sesión cerrada por inactividad.',
      );

  /// Disparado al recibir la notificación FCM de borrado remoto dirigida a
  /// este usuario: elimina los 4 campos sensibles del almacén encriptado
  /// y cierra la sesión, como en un escenario de dispositivo perdido/robado.
  static Future<void> wipeAndLogout() => _closeSession(
        message: 'Tus datos sensibles fueron borrados remotamente.',
        wipeSensitiveData: true,
      );

  static Future<void> _closeSession({
    required String message,
    bool wipeSensitiveData = false,
  }) async {
    final context = AppNavigator.key.currentContext;

    if (wipeSensitiveData) {
      await SensitiveDataStore.wipe();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await SecureSessionStore.clear();

    if (context != null && context.mounted) {
      context.read<LoginProvider>().logout();
      context.read<RegisterProvider>().logout();
      context.read<ToolProvider>().clearTools();
      context.read<RentalProvider>().clearState();
    }

    await AppNavigator.key.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );

    final snackContext = AppNavigator.key.currentContext;
    if (snackContext != null && snackContext.mounted) {
      ScaffoldMessenger.of(snackContext).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
