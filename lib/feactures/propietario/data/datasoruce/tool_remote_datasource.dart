import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../core/config/api_config.dart';
import '../../domain/entitie/tool_entity.dart';

class ToolRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  ToolEntity _fromJson(Map<String, dynamic> j) => ToolEntity(
        id:          j['id']          as String,
        ownerId:     j['owner_id']    as String,
        name:        j['name']        as String,
        description: j['description'] as String? ?? '',
        category:    j['category']    as String? ?? '',
        photoUrl:    j['photo_url']   as String? ?? '',
        photoUrls: (j['photos'] as List<dynamic>?)
                ?.map((p) => (p as Map<String, dynamic>)['photo_url'] as String)
                .toList() ??
            const [],
        estimatedValue: (j['estimated_value'] as num?)?.toDouble() ?? 0.0,
        dailyRate:      (j['daily_rate']      as num?)?.toDouble() ?? 0.0,
        suggestedMinDailyRate: (j['suggested_min_daily_rate'] as num?)?.toDouble() ?? 0.0,
        latitude:       (j['latitude']        as num?)?.toDouble() ?? 0.0,
        longitude:      (j['longitude']       as num?)?.toDouble() ?? 0.0,
        isAvailable: j['is_available'] as bool,
        conditionScore: (j['condition_score'] as num?)?.toDouble() ?? 0.70,
        brand:          j['brand']          as String? ?? 'Generico',
        ageMonths:      j['age_months']      as int? ?? 12,
        city:           j['city']           as String? ?? 'Guadalajara',
        state:          j['state']          as String? ?? 'Jalisco',
        priceSource:    j['price_source']    as String? ?? 'catalogo_semilla',
        wantsInsurance: j['wants_insurance'] as bool? ?? false,
        insuranceMonthlyPremium: (j['insurance_monthly_premium'] as num?)?.toDouble() ?? 0.0,
        createdAt:   j['created_at']  as String,
        updatedAt:   j['updated_at']  as String,
      );

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg  = (body is Map && body['error'] != null)
        ? body['error'] as String : 'Error del servidor';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  Future<List<ToolEntity>> getTools() async {
    try {
      final res = await http.get(
          Uri.parse('$_baseUrl/owner/tools'), headers: await _authHeaders);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ToolEntity> createTool({
    required String name, required String description,
    required String category, required bool isAvailable,
    required double estimatedValue, required double dailyRate,
    double? latitude, double? longitude,
    String brand = 'Generico', int ageMonths = 12,
    String city = 'Guadalajara', String state = 'Jalisco',
    double conditionScore = 0.70,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tools'),
        headers: await _authHeaders,
        body: json.encode({
          'name': name, 'description': description,
          'category': category, 'is_available': isAvailable,
          'estimated_value': estimatedValue, 'daily_rate': dailyRate,
          'latitude': latitude ?? 0.0, 'longitude': longitude ?? 0.0,
          'brand': brand,
          'age_months': ageMonths,
          'city': city,
          'state': state,
          'condition_score': conditionScore,
        }),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ToolEntity> updateTool({
    required String id, String? name, String? description,
    String? category, bool? isAvailable,
    double? estimatedValue, double? dailyRate,
    double? latitude, double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null)        body['name']         = name;
      if (description != null) body['description']  = description;
      if (category != null)    body['category']     = category;
      if (isAvailable != null) body['is_available'] = isAvailable;
      if (estimatedValue != null) body['estimated_value'] = estimatedValue;
      if (dailyRate != null)      body['daily_rate']      = dailyRate;
      if (latitude != null)       body['latitude']        = latitude;
      if (longitude != null)      body['longitude']       = longitude;

      final res = await http.put(
        Uri.parse('$_baseUrl/tools/$id'),
        headers: await _authHeaders,
        body: json.encode(body),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<Map<String, dynamic>> getPricingSuggestion({
    required double estimatedValue,
    required double scoreCondicion,
    required String category,
    required String brand,
    String? name,
    int? ageMonths,
  }) async {
    try {
      final token = await _authHeaders;
      final queryParams = {
        'estimated_value': estimatedValue.toString(),
        'score_condicion': scoreCondicion.toString(),
        'category': category,
        'brand': brand,
      };
      if (name != null) queryParams['name'] = name;
      if (ageMonths != null) queryParams['age_months'] = ageMonths.toString();

      final uri = Uri.parse('$_baseUrl/pricing').replace(
        queryParameters: queryParams,
      );
      final res = await http.get(uri, headers: token);
      _throwIfError(res);
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<void> deleteTool(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/tools/$id'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<String> getSubscriptionPreference() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/subscribe/preference'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['init_point'] as String;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<bool> confirmSubscriptionPayment(String paymentId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/subscribe/confirm'),
        headers: await _authHeaders,
        body: json.encode({'payment_id': paymentId}),
      );
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final isPro = body['is_pro'] as bool? ?? false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_is_pro', isPro);
      return isPro;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<bool> refreshIsPro() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final isPro = body['is_pro'] as bool? ?? false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_is_pro', isPro);
      return isPro;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ToolEntity> uploadPhoto(String toolId, File photo) async {
    try {
      final uri = Uri.parse('$_baseUrl/tools/$toolId/photo');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _authHeaders;
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _throwIfError(response);
      return _fromJson(json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión al subir la foto.'); }
  }

  Future<Map<String, dynamic>> predictCondition(File photo) async {
    try {
      final uri = Uri.parse('$_baseUrl/tools/predict-condition');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _authHeaders;
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        photo.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _throwIfError(response);
      return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on AppError { rethrow; }
    catch (e) {
      throw const AppError(statusCode: 0, message: 'Sin conexión al predecir desgaste.');
    }
  }

  Future<Map<String, dynamic>> autoValuate({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
    int? ageMonths,
    double? precioBaseManual,
    bool ticketValidado = false,
  }) async {
    try {
      final queryParams = {
        'name': name,
        'score_condicion': scoreCondicion.toString(),
        'category': category,
        'brand': brand,
      };
      if (ageMonths != null) queryParams['age_months'] = ageMonths.toString();
      if (precioBaseManual != null) {
        queryParams['precio_base_manual'] = precioBaseManual.toString();
        queryParams['ticket_validado'] = ticketValidado.toString();
      }

      final uri = Uri.parse('$_baseUrl/tools/auto-valuate').replace(
        queryParameters: queryParams,
      );
      final res = await http.get(uri, headers: await _authHeaders);
      _throwIfError(res);
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  // El OCR del ticket puede tardar decenas de segundos (arranque en frío del
  // worker de PaddleOCR en el servicio de ML) — una sola petición HTTP tan
  // larga se topaba con el timeout del proxy de Railway y se cortaba a
  // medias aunque el servidor sí hubiera terminado bien. Ahora el POST
  // arranca el OCR en segundo plano y responde de inmediato con un job_id;
  // aquí se pregunta el estatus cada 2s hasta que termine. El resultado
  // final tiene el mismo formato (valid/detected_price/confidence/error)
  // que antes devolvía el POST directo, para no tocar nada en
  // _pickTicketImage.
  Future<Map<String, dynamic>> extractTicketPrice(File photo) async {
    try {
      final uri = Uri.parse('$_baseUrl/tools/extract-ticket-price');
      final request = http.MultipartRequest('POST', uri);

      final headers = await _authHeaders;
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamedResponse = await request.send();
      final startResponse = await http.Response.fromStream(streamedResponse);
      _throwIfError(startResponse);

      final jobId = (json.decode(utf8.decode(startResponse.bodyBytes))
          as Map<String, dynamic>)['job_id'] as String;

      // 65 intentos x 2s = 130s máximo, por encima del contexto de 120s que
      // usa Go para este job (ticket_job_store.go), para no rendirse antes
      // que el propio backend.
      for (var intento = 0; intento < 65; intento++) {
        await Future.delayed(const Duration(seconds: 2));

        final statusRes = await http.get(
          Uri.parse('$_baseUrl/tools/extract-ticket-price/$jobId'),
          headers: await _authHeaders,
        );
        _throwIfError(statusRes);
        final statusBody =
            json.decode(utf8.decode(statusRes.bodyBytes)) as Map<String, dynamic>;

        if (statusBody['status'] == 'processing') continue;

        return {
          'valid': statusBody['valid'] ?? false,
          'detected_price': statusBody['detected_price'],
          'confidence': statusBody['confidence'],
          'error': statusBody['error'],
        };
      }

      throw const AppError(
        statusCode: 0,
        message: 'La lectura del ticket tardó demasiado. Intenta de nuevo.',
      );
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión al leer el ticket.'); }
  }

  Future<String> getInsurancePreference(String toolId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tools/$toolId/insurance/preference'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['init_point'] as String;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión al iniciar el pago del seguro.'); }
  }

  Future<ToolEntity> confirmInsurancePayment(String toolId, String paymentId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tools/$toolId/insurance/confirm'),
        headers: await _authHeaders,
        body: json.encode({'payment_id': paymentId}),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión al confirmar el pago del seguro.'); }
  }

  Future<ToolEntity> cancelInsurance(String toolId) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tools/$toolId/insurance/cancel'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión al cancelar el seguro.'); }
  }
}