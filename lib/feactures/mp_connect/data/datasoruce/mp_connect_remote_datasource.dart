import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/config/api_config.dart';

class MpConnectRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Error del servidor';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  Future<bool> getStatus() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/mp-connect/status'), headers: await _authHeaders);
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['connected'] as bool? ?? false;
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<String> getAuthURL() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/mp-connect/start'), headers: await _authHeaders);
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['auth_url'] as String;
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }
}
