import 'package:flutter/material.dart';
import '../../../propietario/domain/entitie/tool.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart'; // Importado
import '../../domain/usesCases/delete_tool_usecase.dart';

class PropietarioViewModel extends ChangeNotifier {
  final GetToolsUseCase getToolsUseCase;
  final CreateToolUseCase createToolUseCase;
  final UpdateToolUseCase updateToolUseCase; // Agregado
  final DeleteToolUseCase deleteToolUseCase;

  PropietarioViewModel({
    required this.getToolsUseCase,
    required this.createToolUseCase,
    required this.updateToolUseCase, // Agregado
    required this.deleteToolUseCase,
  });

  List<Tool> _tools = [];
  List<Tool> get tools => _tools;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadTools(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tools = await getToolsUseCase.call(token);
    } catch (e) {
      debugPrint("Error loading tools: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createTool(String token, String name, String desc, String cat) async {
    await createToolUseCase.call(token, {
      'name': name,
      'description': desc,
      'category': cat,
      'is_available': true
    });
    await loadTools(token);
  }

  // MÉTODO AGREGADO PARA EL UPDATE
  Future<void> toggleAvailability(String token, String id, bool currentStatus) async {
    await updateToolUseCase.call(token, id, {
      'is_available': !currentStatus
    });
    await loadTools(token); // Recarga para ver el cambio reflejado
  }

  Future<void> deleteTool(String token, String id) async {
    await deleteToolUseCase.call(token, id);
    await loadTools(token);
  }
}