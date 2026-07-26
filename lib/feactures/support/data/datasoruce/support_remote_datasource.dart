import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/services/session_prefs_store.dart';

import '../../../../core/error/app_error.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entitie/support_message_entity.dart';
import '../../domain/entitie/support_thread_entity.dart';

class SupportRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final token = await SessionPrefsStore.token() ?? '';
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

  Future<List<SupportMessageEntity>> getMyMessages() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/support/messages'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list
          .map((e) => SupportMessageEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<SupportMessageEntity> sendMyMessage(String message) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/support/messages'),
        headers: await _authHeaders,
        body: json.encode({'message': message}),
      );
      _throwIfError(res);
      return SupportMessageEntity.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<List<SupportThreadEntity>> getThreads() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/support/threads'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list
          .map((e) => SupportThreadEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<List<SupportMessageEntity>> getThreadMessages(String ownerId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/support/threads/$ownerId/messages'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list
          .map((e) => SupportMessageEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<SupportMessageEntity> sendThreadMessage(String ownerId, String message) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/support/threads/$ownerId/messages'),
        headers: await _authHeaders,
        body: json.encode({'message': message}),
      );
      _throwIfError(res);
      return SupportMessageEntity.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }
}
