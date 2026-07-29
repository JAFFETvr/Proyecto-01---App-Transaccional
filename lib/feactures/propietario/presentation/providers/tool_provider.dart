import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/services/session_prefs_store.dart';
import '../../../../../core/services/image_compression_service.dart';
import '../../../../../core/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';
import '../../domain/usesCases/get_tools_usecase.dart';
import '../../domain/usesCases/create_tool_usecase.dart';
import '../../domain/usesCases/update_tool_usecase.dart';
import '../../domain/usesCases/delete_tool_usecase.dart';
import '../../domain/usesCases/get_pricing_suggestion_usecase.dart';
import '../../domain/usesCases/subscribe_usecase.dart';
import '../../domain/usesCases/predict_condition_usecase.dart';
import '../../domain/usesCases/auto_valuate_usecase.dart';
import '../../domain/usesCases/extract_ticket_price_usecase.dart';
import '../../domain/usesCases/upload_tool_photo_usecase.dart';
import '../../domain/usesCases/get_insurance_preference_usecase.dart';
import '../../domain/usesCases/confirm_insurance_payment_usecase.dart';
import '../../domain/usesCases/reconcile_insurance_usecase.dart';
import '../../domain/usesCases/cancel_insurance_usecase.dart';

class ToolProvider extends ChangeNotifier {
  final GetToolsUseCase _getTools;
  final CreateToolUseCase _createTool;
  final UpdateToolUseCase _updateTool;
  final DeleteToolUseCase _deleteTool;
  final GetPricingSuggestionUseCase _getPricingSuggestion;
  final PredictConditionUseCase _predictCondition;
  final AutoValuateUseCase _autoValuate;
  final ExtractTicketPriceUseCase _extractTicketPrice;
  final UploadToolPhotoUseCase _uploadToolPhoto;
  final GetSubscriptionPreferenceUseCase _getSubscriptionPreference;
  final ConfirmSubscriptionPaymentUseCase _confirmSubscriptionPayment;
  final RefreshIsProUseCase _refreshIsPro;
  final GetInsurancePreferenceUseCase _getInsurancePreference;
  final ConfirmInsurancePaymentUseCase _confirmInsurancePayment;
  final ReconcileInsuranceUseCase _reconcileInsurance;
  final CancelInsuranceUseCase _cancelInsurance;

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
    required ExtractTicketPriceUseCase extractTicketPrice,
    required UploadToolPhotoUseCase uploadToolPhoto,
    required GetSubscriptionPreferenceUseCase getSubscriptionPreference,
    required ConfirmSubscriptionPaymentUseCase confirmSubscriptionPayment,
    required RefreshIsProUseCase refreshIsPro,
    required GetInsurancePreferenceUseCase getInsurancePreference,
    required ConfirmInsurancePaymentUseCase confirmInsurancePayment,
    required ReconcileInsuranceUseCase reconcileInsurance,
    required CancelInsuranceUseCase cancelInsurance,
  })  : _getTools = getTools,
        _createTool = createTool,
        _updateTool = updateTool,
        _deleteTool = deleteTool,
        _getPricingSuggestion = getPricingSuggestion,
        _predictCondition = predictCondition,
        _autoValuate = autoValuate,
        _extractTicketPrice = extractTicketPrice,
        _uploadToolPhoto = uploadToolPhoto,
        _getSubscriptionPreference = getSubscriptionPreference,
        _confirmSubscriptionPayment = confirmSubscriptionPayment,
        _refreshIsPro = refreshIsPro,
        _getInsurancePreference = getInsurancePreference,
        _confirmInsurancePayment = confirmInsurancePayment,
        _reconcileInsurance = reconcileInsurance,
        _cancelInsurance = cancelInsurance;

  Future<void> checkSubscriptionStatus() async {
    _isPro = await SessionPrefsStore.isPro();
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

  Future<bool> refreshProStatus() async {
    try {
      _isPro = await _refreshIsPro.execute();
      notifyListeners();
      return _isPro;
    } catch (_) {
      return _isPro;
    }
  }

  // Debe coincidir con MinRequiredPhotos en tool_service.go (backend).
  static const minRequiredPhotos = 2;

  // Mapeo de score a etiqueta: debe coincidir con SCORE_MAPPING en api/routes_tool.py.
  static String wearLevelForScore(double score) {
    if (score >= 0.9) return 'Nuevo';
    if (score >= 0.5) return 'Buen Estado';
    return 'Desgastado';
  }

  static double scoreForWearLevel(String level) {
    if (level == 'Nuevo') return 1.0;
    if (level == 'Buen Estado') return 0.8;
    if (level == 'Desgastado') return 0.5;
    return 0.7;
  }

  /// Wear level a partir del PEOR score entre todas las fotos subidas.
  static String worstWearLevel(List<double> scores) {
    if (scores.isEmpty) return 'Nuevo';
    return wearLevelForScore(scores.reduce((a, b) => a < b ? a : b));
  }

  /// Comprime la foto (Isolate, no bloquea la UI) y la evalúa con la CNN.
  /// Devuelve el archivo comprimido —el que debe guardarse/subirse— y su
  /// score de condición, o null si la imagen no es válida (ver [error]).
  Future<({File file, double score})?> evaluatePhotoCondition(
    File rawPhoto,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final file = await ImageCompressionService.compress(rawPhoto);
      final pred = await _predictCondition.execute(file);
      final score = (pred['score_condicion'] as num?)?.toDouble() ?? 0.70;
      return (file: file, score: score);
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (e, stack) {
      debugPrint('FLUTTER RUNTIME ERROR IN evaluatePhotoCondition: $e');
      debugPrint(stack.toString());
      _error = 'Sin conexión al predecir desgaste: $e';
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
    double? precioBaseManual,
    bool ticketValidado = false,
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
        precioBaseManual: precioBaseManual,
        ticketValidado: ticketValidado,
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

  /// Si es válido, se usa como precio_base_manual verificado en autoValuate.
  Future<Map<String, dynamic>?> extractTicketPrice(File rawPhoto) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final photo = await ImageCompressionService.compress(rawPhoto);
      final res = await _extractTicketPrice.execute(photo);
      debugPrint('FLUTTER DEBUG: extractTicketPrice Response -> $res');
      return res;
    } on AppError catch (e) {
      debugPrint('FLUTTER DEBUG: extractTicketPrice AppError -> ${e.userMessage}');
      _error = e.userMessage;
      return null;
    } catch (e, stack) {
      debugPrint('FLUTTER DEBUG: extractTicketPrice Unexpected Error -> $e');
      debugPrint(stack.toString());
      _error = 'Sin conexión al leer el ticket: $e';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Crea la preferencia de pago en Mercado Pago para el seguro mensual de
  /// esta herramienta específica.
  Future<String?> getInsurancePreference(String toolId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _getInsurancePreference.execute(toolId);
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al iniciar el pago del seguro.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Verifica con Mercado Pago que el pago del seguro fue aprobado y
  /// actualiza la herramienta localmente si se activó correctamente.
  Future<bool> confirmInsurancePayment(String toolId, String paymentId) async {
    try {
      final updated = await _confirmInsurancePayment.execute(toolId, paymentId);
      final idx = _tools.indexWhere((t) => t.id == toolId);
      if (idx != -1) _tools[idx] = updated;
      notifyListeners();
      return updated.wantsInsurance;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'El pago no se pudo confirmar todavía.';
      return false;
    }
  }

  /// Respaldo sin payment_id, vía external_reference en MP.
  Future<bool> reconcileInsurance(String toolId) async {
    try {
      final updated = await _reconcileInsurance.execute(toolId);
      final idx = _tools.indexWhere((t) => t.id == toolId);
      if (idx != -1) _tools[idx] = updated;
      notifyListeners();
      return updated.wantsInsurance;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Cancela el seguro activo de la herramienta. No hay reembolso: la prima
  /// ya pagada cubre el mes en curso, solo se detiene la renovación.
  Future<bool> cancelInsurance(String toolId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _cancelInsurance.execute(toolId);
      final idx = _tools.indexWhere((t) => t.id == toolId);
      if (idx != -1) _tools[idx] = updated;
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al cancelar el seguro.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
