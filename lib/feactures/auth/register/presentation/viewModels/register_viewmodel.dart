import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/error/app_error.dart';
import '../../data/di/register_di.dart';
import '../../domain/entitie/user_entity.dart';
import '../../domain/usesCases/register_usecase.dart';

class RegisterViewModel extends ChangeNotifier {
  final RegisterUseCase _registerUseCase =
      RegisterDI.provideRegisterUseCase();

  bool _loading = false;
  String? _errorMessage;
  UserEntity? _user;

  bool get loading         => _loading;
  String? get errorMessage => _errorMessage;
  UserEntity? get user     => _user;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _registerUseCase.execute(
          name: name, email: email, password: password, role: role);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token',  _user!.token);
      await prefs.setString('user_id',    _user!.id);
      await prefs.setString('user_name',  _user!.name);
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('user_role',  _user!.role);

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