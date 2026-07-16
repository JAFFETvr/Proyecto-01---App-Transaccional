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
import '../../domain/usesCases/upload_tool_photo_usecase.dart';

class ToolProvider extends ChangeNotifier {//
  final GetToolsUseCase _getTools;
  final CreateToolUseCase _createTool;
  final UpdateToolUseCase _updateTool;
  final DeleteToolUseCase _deleteTool;
  final GetPricingSuggestionUseCase _getPricingSuggestion;
  final PredictConditionUseCase _predictCondition;
  final AutoValuateUseCase _autoValuate;
  final UploadToolPhotoUseCase _uploadToolPhoto;
  final GetSubscriptionPreferenceUseCase _getSubscriptionPreference;
  final ConfirmSubscriptionPaymentUseCase _confirmSubscriptionPayment;
  final RefreshIsProUseCase _refreshIsPro;

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
    required UploadToolPhotoUseCase uploadToolPhoto,
    required GetSubscriptionPreferenceUseCase getSubscriptionPreference,
    required ConfirmSubscriptionPaymentUseCase confirmSubscriptionPayment,
    required RefreshIsProUseCase refreshIsPro,
  })  : _getTools = getTools,
        _createTool = createTool,
        _updateTool = updateTool,
        _deleteTool = deleteTool,
        _getPricingSuggestion = getPricingSuggestion,
        _predictCondition = predictCondition,
        _autoValuate = autoValuate,
        _uploadToolPhoto = uploadToolPhoto,
        _getSubscriptionPreference = getSubscriptionPreference,
        _confirmSubscriptionPayment = confirmSubscriptionPayment,
        _refreshIsPro = refreshIsPro;

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

  Future<ToolEntity?> createTool({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
    required double estimatedValue,
    required double dailyRate,
    double? latitude,
    double? longitude,
    String brand = 'Generico',
    int ageMonths = 12,
    double conditionScore = 0.70,
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
        brand: brand,
        ageMonths: ageMonths,
        conditionScore: conditionScore,
      );
      _tools.add(tool);
      return tool;
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ToolEntity?> updateTool({
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
      return updated;
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sube la foto tomada/elegida en el formulario hacia el backend
  /// (POST /tools/{id}/photo) y actualiza la entidad local con la
  /// photo_url resultante. No lanza: si falla, deja el error en [error]
  /// y retorna false, para no bloquear el guardado de la herramienta.
  Future<bool> uploadPhoto(String toolId, File photo) async {
    try {
      final updated = await _uploadToolPhoto.execute(toolId, photo);
      final idx = _tools.indexWhere((t) => t.id == toolId);
      if (idx != -1) _tools[idx] = updated;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al subir la foto.';
      return false;
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

  /// Pide al backend el init_point de Checkout Pro de Mercado Pago para
  /// pagar la suscripción. Null si falló (ver [error]).
  Future<String?> getSubscriptionPreference() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      return await _getSubscriptionPreference.execute();
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Confirma un pago de suscripción directamente contra MP usando el payment_id
  /// devuelto en la URL de retorno del checkout (no depende del webhook).
  Future<bool> confirmSubscriptionPayment(String paymentId) async {
    try {
      _isPro = await _confirmSubscriptionPayment.execute(paymentId);
      notifyListeners();
      return _isPro;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
      return false;
    }
  }

  /// Refresca is_pro desde el backend (el webhook de MP lo activa de forma asíncrona).
  Future<bool> refreshProStatus() async {
    try {
      _isPro = await _refreshIsPro.execute();
      notifyListeners();
      return _isPro;
    } catch (_) {
      return _isPro;
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
    int? ageMonths,
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
        ageMonths: ageMonths,
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
