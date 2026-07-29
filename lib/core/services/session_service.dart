import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_navigator.dart';
import '../session/session_provider.dart';
import 'session_prefs_store.dart';
import 'secure_session_store.dart';
import 'sensitive_data_store.dart';
import '../../feactures/auth/login/presentation/providers/login_provider.dart';
import '../../feactures/auth/login/presentation/screes/login_screen.dart';
import '../../feactures/auth/register/presentation/providers/register_provider.dart';
import '../../feactures/propietario/presentation/providers/tool_provider.dart';
import '../../feactures/checkout/presentation/providers/rental_provider.dart';

/// Cierra sesión sin BuildContext (usado por watchdog de inactividad y FCM).
class SessionService {
  static Future<void> logoutForInactivity() => _closeSession(
        message: 'Sesión cerrada por inactividad.',
      );

  /// Borra los datos sensibles y cierra sesión (dispositivo perdido/robado).
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

    await SessionPrefsStore.clear();
    await SecureSessionStore.clear();

    if (context != null && context.mounted) {
      context.read<SessionProvider>().clear();
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
