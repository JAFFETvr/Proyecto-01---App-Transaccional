import 'package:flutter/material.dart';

import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart';
import '../../domain/usesCases/delete_tool_usecase.dart';

class ToolProvider extends ChangeNotifier {
  final GetToolsUseCase _getTools;
  final CreateToolUseCase _createTool;
  final UpdateToolUseCase _updateTool;
  final DeleteToolUseCase _deleteTool;

  List<ToolEntity> _tools = [];
  bool _loading = false;
  String? _error;

  List<ToolEntity> get tools  => List.unmodifiable(_tools);
  bool get loading            => _loading;
  String? get error           => _error;

  int get totalTools     => _tools.length;
  int get availableCount => _tools.where((t) => t.isAvailable).length;
  int get rentedCount    => _tools.where((t) => !t.isAvailable).length;

  ToolProvider({
    required GetToolsUseCase getTools,
    required CreateToolUseCase createTool,
    required UpdateToolUseCase updateTool,
    required DeleteToolUseCase deleteTool,
  })  : _getTools = getTools,
        _createTool = createTool,
        _updateTool = updateTool,
        _deleteTool = deleteTool;

  Future<void> fetchTools() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tools = await _getTools.execute();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createTool({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final tool = await _createTool.execute(
        name: name,
        description: description,
        category: category,
        isAvailable: isAvailable,
      );
      _tools.add(tool);
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTool({
    required String id,
    String? name,
    String? description,
    String? category,
    bool? isAvailable,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _updateTool.execute(
        id: id,
        name: name,
        description: description,
        category: category,
        isAvailable: isAvailable,
      );
      final idx = _tools.indexWhere((t) => t.id == id);
      if (idx != -1) _tools[idx] = updated;
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTool(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _deleteTool.execute(id);
      _tools.removeWhere((t) => t.id == id);
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
