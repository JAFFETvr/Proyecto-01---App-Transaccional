import 'package:flutter/material.dart';

import '../../../../../core/error/app_error.dart';
import '../../../../../core/services/session_prefs_store.dart';
import '../../../../../core/services/secure_session_store.dart';
import '../../../../../core/services/sensitive_data_store.dart';
import '../../domain/entitie/user_entity.dart';
import '../../domain/usesCases/register_usecase.dart';
import '../../domain/usesCases/verify_kyc_usecase.dart';

class RegisterProvider extends ChangeNotifier {
  final RegisterUseCase _registerUseCase;
  final VerifyKycUseCase _verifyKycUseCase;

  bool _loading = false;
  String? _errorMessage;
  UserEntity? _user;

  bool get loading           => _loading;
  String? get errorMessage   => _errorMessage;
  UserEntity? get user       => _user;

  RegisterProvider({
    required RegisterUseCase registerUseCase,
    required VerifyKycUseCase verifyKycUseCase,
  })  : _registerUseCase = registerUseCase,
        _verifyKycUseCase = verifyKycUseCase;

  void logout() {
    _user = null;
    _errorMessage = null;
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> verifyKyc({
    required String inePath,
    required String selfiePath,
    required String curp,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _verifyKycUseCase.execute(
        inePath: inePath,
        selfiePath: selfiePath,
        curp: curp,
      );
      return res;
    } on AppError catch (e) {
      _errorMessage = e.userMessage;
      return null;
    } catch (_) {
      _errorMessage = 'Sin conexión al servidor de visión KYC.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String ine,
  }) async {
    _loading = true;
    _errorMessage = null;
    _user = null;
    notifyListeners();

    try {
      _user = await _registerUseCase.execute(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        ine: ine,
      );

      await SessionPrefsStore.saveSession(
        token: _user!.token,
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.role,
        phone: _user!.phone,
        ine: _user!.ine,
      );

      await SecureSessionStore.saveToken(_user!.token);
      await SecureSessionStore.saveLastActive(DateTime.now());

      await SensitiveDataStore.saveAll(
        name: _user!.name,
        email: _user!.email,
        phone: _user!.phone,
        ine: _user!.ine,
      );

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
