import 'package:flutter/material.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/repositories/mp_connect_repository.dart';

class MpConnectProvider extends ChangeNotifier {
  final MpConnectRepository _repository;

  MpConnectProvider({required MpConnectRepository repository})
      : _repository = repository;

  bool _connected = false;
  bool _loading = false;
  String? _error;

  bool get connected => _connected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchStatus() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _connected = await _repository.getStatus();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> startConnect() async {
    _error = null;
    try {
      return await _repository.getAuthURL();
    } on AppError catch (e) {
      _error = e.userMessage;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'No se pudo iniciar la vinculación con Mercado Pago.';
      notifyListeners();
      return null;
    }
  }
}
