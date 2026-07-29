import 'package:flutter/foundation.dart';

import '../services/session_prefs_store.dart';

/// Expone el perfil de sesión de solo lectura; llamar [refresh] tras login/registro.
class SessionProvider extends ChangeNotifier {
  String _userName = '';
  String _userId = '';
  String _userEmail = '';
  String _userRole = '';
  bool _isPro = false;

  String get userName => _userName;
  String get userId => _userId;
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  bool get isPro => _isPro;

  SessionProvider() {
    refresh();
  }

  /// Recarga el perfil desde el almacén plano. Se invoca al arrancar la app y
  /// después de un login/registro exitoso.
  Future<void> refresh() async {
    _userName = await SessionPrefsStore.userName();
    _userId = await SessionPrefsStore.userId();
    _userEmail = await SessionPrefsStore.userEmail();
    _userRole = await SessionPrefsStore.userRole();
    _isPro = await SessionPrefsStore.isPro();
    notifyListeners();
  }

  /// Limpia el perfil en memoria al cerrar sesión.
  void clear() {
    _userName = '';
    _userId = '';
    _userEmail = '';
    _userRole = '';
    _isPro = false;
    notifyListeners();
  }
}
