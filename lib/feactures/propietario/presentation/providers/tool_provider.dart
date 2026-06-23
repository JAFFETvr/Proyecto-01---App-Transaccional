import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart';
import '../../domain/usesCases/delete_tool_usecase.dart';
import '../../domain/usesCases/get_pricing_suggestion_usecase.dart';
import '../../domain/usesCases/subscribe_usecase.dart';
import '../../domain/usesCases/predict_condition_usecase.dart';
import '../../domain/usesCases/auto_valuate_usecase.dart';

class ToolProvider extends ChangeNotifier {
  final GetToolsUseCase _getTools;
  final CreateToolUseCase _createTool;
  final UpdateToolUseCase _updateTool;
  final DeleteToolUseCase _deleteTool;
  final GetPricingSuggestionUseCase _getPricingSuggestion;
  final PredictConditionUseCase _predictCondition;
  final AutoValuateUseCase _autoValuate;
  final SubscribeUseCase _subscribe;

  List<ToolEntity> _tools = [];
  bool _loading = false;
  String? _error;
  bool _isPro = false;

  List<ToolEntity> get tools  => List.unmodifiable(_tools);
  bool get loading            => _loading;
  String? get error           => _error;
  bool get isPro              => _isPro;

  int get totalTools     => _tools.length;
  int get availableCount => _tools.where((t) => t.isAvailable).length;
  int get rentedCount    => _tools.where((t) => !t.isAvailable).length;

  void clearTools() {
    _tools = [];
    _error = null;
    _loading = false;
    _isPro = false;
    notifyListeners();
  }

  ToolProvider({
    required GetToolsUseCase getTools,
    required CreateToolUseCase createTool,
    required UpdateToolUseCase updateTool,
    required DeleteToolUseCase deleteTool,
    required GetPricingSuggestionUseCase getPricingSuggestion,
    required PredictConditionUseCase predictCondition,
    required AutoValuateUseCase autoValuate,
    required SubscribeUseCase subscribe,
  })  : _getTools = getTools,
        _createTool = createTool,
        _updateTool = updateTool,
        _deleteTool = deleteTool,
        _getPricingSuggestion = getPricingSuggestion,
        _predictCondition = predictCondition,
        _autoValuate = autoValuate,
        _subscribe = subscribe;

  Future<void> checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('user_is_pro') ?? false;
    notifyListeners();
  }

  Future<void> fetchTools() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await checkSubscriptionStatus();
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
    required double estimatedValue,
    required double dailyRate,
    double? latitude,
    double? longitude,
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
        estimatedValue: estimatedValue,
        dailyRate: dailyRate,
        latitude: latitude,
        longitude: longitude,
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
    double? estimatedValue,
    double? dailyRate,
    double? latitude,
    double? longitude,
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
        estimatedValue: estimatedValue,
        dailyRate: dailyRate,
        latitude: latitude,
        longitude: longitude,
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

  Future<Map<String, dynamic>> fetchPricingSuggestion({
    required double estimatedValue,
    required double scoreCondicion,
    required String category,
    required String brand,
  }) async {
    try {
      return await _getPricingSuggestion.execute(
        estimatedValue: estimatedValue,
        scoreCondicion: scoreCondicion,
        category: category,
        brand: brand,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> subscribePro() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _subscribe.execute();
      if (success) {
        _isPro = true;
      }
      return success;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> predictCondition(File photo) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _predictCondition.execute(photo);
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al predecir desgaste.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> autoValuate({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _autoValuate.execute(
        name: name,
        scoreCondicion: scoreCondicion,
        category: category,
        brand: brand,
      );
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al valuar herramienta.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
