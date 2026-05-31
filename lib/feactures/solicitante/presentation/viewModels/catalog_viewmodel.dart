import 'package:flutter/material.dart';
import '../../../../../shared/error/app_error.dart';
import '../../data/di/solicitante_di.dart';
import '../../domain/entitie/tool_entity.dart';

class CatalogViewModel extends ChangeNotifier {
  final _getCatalog = SolicitanteDI.provideGetCatalog();

  List<ToolEntity> _all  = [];
  bool _loading          = false;
  String? _error;
  String _search         = '';
  String _filterCategory = 'Todos';
  bool _onlyAvailable    = false;

  bool get loading             => _loading;
  String? get error            => _error;
  String get search            => _search;
  String get filterCategory    => _filterCategory;
  bool get onlyAvailable       => _onlyAvailable;
  int get totalCount           => _all.length;

  List<String> get categories {
    final cats = _all.map((t) => t.category)
        .where((c) => c.isNotEmpty).toSet().toList()..sort();
    return ['Todos', ...cats];
  }

  List<ToolEntity> get filtered => _all.where((t) {
        final ms = _search.isEmpty ||
            t.name.toLowerCase().contains(_search.toLowerCase()) ||
            t.category.toLowerCase().contains(_search.toLowerCase());
        final mc = _filterCategory == 'Todos' ||
            t.category == _filterCategory;
        final ma = !_onlyAvailable || t.isAvailable;
        return ms && mc && ma;
      }).toList();

  Future<void> fetchTools() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _all = await _getCatalog.execute();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  void setSearch(String v)         { _search = v; notifyListeners(); }
  void setCategory(String v)       { _filterCategory = v; notifyListeners(); }
  void setOnlyAvailable(bool v)    { _onlyAvailable = v; notifyListeners(); }
}