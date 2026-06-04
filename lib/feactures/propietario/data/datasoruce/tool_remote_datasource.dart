import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';

class ToolRemoteDatasource {
  static const _baseUrl = 'http://100.50.210.8:8080/api';

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
        isAvailable: j['is_available'] as bool,
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
          Uri.parse('$_baseUrl/tools'), headers: _jsonHeaders);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ToolEntity> createTool({
    required String name, required String description,
    required String category, required bool isAvailable,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tools'),
        headers: await _authHeaders,
        body: json.encode({
          'name': name, 'description': description,
          'category': category, 'is_available': isAvailable,
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
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null)        body['name']         = name;
      if (description != null) body['description']  = description;
      if (category != null)    body['category']     = category;
      if (isAvailable != null) body['is_available'] = isAvailable;

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
}