import 'package:flutter/material.dart';

import '../../../../../core/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../domain/usesCases/get_catalog_usecase.dart';

class CatalogProvider extends ChangeNotifier {
  final GetCatalogUseCase _getCatalog;

  List<ToolEntity> _all = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  String _filterCategory = 'Todos';
  bool _onlyAvailable = false;

  bool get loading             => _loading;
  String? get error            => _error;
  String get search            => _search;
  String get filterCategory    => _filterCategory;
  bool get onlyAvailable       => _onlyAvailable;
  int get totalCount           => _all.length;
  List<ToolEntity> get allTools => List.unmodifiable(_all);

  List<String> get categories {
    final cats = _all
        .map((t) => t.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Todos', ...cats];
  }

  List<ToolEntity> get filtered => _all.where((t) {
        final matchCategory = _filterCategory == 'Todos' ||
            t.category == _filterCategory;
        final matchAvailable = !_onlyAvailable || t.isAvailable;

        return matchCategory && matchAvailable;
      }).toList();

  CatalogProvider({required GetCatalogUseCase getCatalog})
      : _getCatalog = getCatalog;

  Future<void> fetchTools() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _all = await _getCatalog.execute(
        onlyAvailable: _onlyAvailable,
        search: _search,
      );
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
    fetchTools();
  }

  void setCategory(String value) {
    _filterCategory = value;
    notifyListeners();
  }

  void setOnlyAvailable(bool value) {
    _onlyAvailable = value;
    notifyListeners();
    fetchTools();
  }
}
