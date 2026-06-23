import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/error/app_error.dart';
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

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _loginUseCase.execute(
        email: email,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token',  _user!.token);
      await prefs.setString('user_id',    _user!.id);
      await prefs.setString('user_name',  _user!.name);
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('user_role',  _user!.role);
      await prefs.setBool('user_is_pro',  _user!.isPro);

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
