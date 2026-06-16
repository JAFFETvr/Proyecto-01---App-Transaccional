import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/user_entity.dart';

class RegisterRemoteDatasource {
  static String get _baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080/api';
    return 'http://localhost:8080/api';
  }

  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;

      if (response.statusCode == 201) {
        final user = body['user'] as Map<String, dynamic>;
        return UserEntity(
          id:    user['id']    as String,
          name:  user['name']  as String,
          email: user['email'] as String,
          role:  user['role']  as String,
          token: body['token'] as String,
        );
      }

      throw AppError(
        statusCode: response.statusCode,
        message: body['error'] as String? ?? 'Error desconocido',
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(
          statusCode: 0, message: 'Sin conexión al servidor.');
    }
  }
}