import 'package:flutter/foundation.dart';

import '../../domain/entitie/support_thread_entity.dart';
import '../../domain/repositories/support_repository.dart';

/// Lista de propietarios con conversación de soporte activa (uso del admin).
class SupportThreadsProvider extends ChangeNotifier {
  final SupportRepository _repository;

  SupportThreadsProvider(this._repository);

  List<SupportThreadEntity> _threads = [];
  bool _loading = false;
  String? _error;

  List<SupportThreadEntity> get threads => List.unmodifiable(_threads);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchThreads() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _threads = await _repository.getThreads();
    } catch (_) {
      _error = 'No se pudieron cargar las conversaciones.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
