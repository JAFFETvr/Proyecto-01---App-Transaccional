import 'package:flutter/material.dart';

import '../../../../../core/error/app_error.dart';
import '../../../../../core/services/session_prefs_store.dart';
import '../../../../../core/services/secure_session_store.dart';
import '../../../../../core/services/sensitive_data_store.dart';
import '../../domain/entitie/user_entity.dart';
import '../../domain/usesCases/login_usecase.dart';

class LoginProvider extends ChangeNotifier {
  final LoginUseCase _loginUseCase;

  bool _loading = false;
  String? _errorMessage;
  UserEntity? _user;

  bool get loading           => _loading;
  String? get errorMessage   => _errorMessage;
  UserEntity? get user       => _user;

  LoginProvider({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase;

  void logout() {
    _user = null;
    _errorMessage = null;
    _loading = false;
    notifyListeners();
  }

  /// Sincroniza el estado de sesión con un usuario ya autenticado por otro
  /// flujo (p. ej. justo después de un registro exitoso), sin volver a
  /// pegarle al backend. Sin esto, `user` queda en null tras registrarse y
  /// toda la UI que lee la sesión desde aquí (cuenta, mis rentas) aparece
  /// vacía hasta el siguiente login manual.
  void setUser(UserEntity user) {
    _user = user;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null;
    _user = null;
    notifyListeners();

    try {
      _user = await _loginUseCase.execute(
        email: email,
        password: password,
      );

      await SessionPrefsStore.saveSession(
        token: _user!.token,
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.role,
        isPro: _user!.isPro,
      );

      // Token y marca de tiempo de actividad también en almacén encriptado,
      // para que el watchdog de inactividad los use tras un cierre total de la app.
      await SecureSessionStore.saveToken(_user!.token);
      await SecureSessionStore.saveLastActive(DateTime.now());

      // Datos sensibles del perfil en almacén encriptado, borrables de forma
      // remota vía la notificación FCM dirigida a este usuario.
      await SensitiveDataStore.saveAll(
        name: _user!.name,
        email: _user!.email,
        phone: _user!.phone,
        ine: _user!.ine,
      );
      // TODO: reactivar cuando Firebase tenga credenciales
      // await FcmService.subscribeToUserTopic(_user!.id);

    } on AppError catch (e) {
      _errorMessage = e.userMessage;
    } catch (_) {
      _errorMessage = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
