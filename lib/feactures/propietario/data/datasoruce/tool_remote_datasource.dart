import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/error/app_error.dart';
import '../../../../../shared/config/api_config.dart';
import '../../domain/entitie/tool_entity.dart';

class ToolRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  // Lee el JWT guardado y lo pone en el header
  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  ToolEntity _fromJson(Map<String, dynamic> j) => ToolEntity(
        id:          j['id']          as String,
        ownerId:     j['owner_id']    as String,
        name:        j['name']        as String,
        description: j['description'] as String? ?? '',
        category:    j['category']    as String? ?? '',
        photoUrl:    j['photo_url']   as String? ?? '',
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
      // We must remove Content-Type from headers because MultipartRequest will calculate it with boundary automatically.
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
  }) async {
    try {
      final queryParams = {
        'name': name,
        'score_condicion': scoreCondicion.toString(),
        'category': category,
        'brand': brand,
      };
      if (ageMonths != null) queryParams['age_months'] = ageMonths.toString();

      final uri = Uri.parse('$_baseUrl/tools/auto-valuate').replace(
        queryParameters: queryParams,
      );
      final res = await http.get(uri, headers: await _authHeaders);
      _throwIfError(res);
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }
}