import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/user_entity.dart';

// Única clase que sabe hablar con el endpoint real de tu API Go.
class LoginRemoteDatasource {
  // Emulador Android → 10.0.2.2 | Simulador iOS → localhost
  static const _baseUrl = 'http://100.50.210.8:8080/api';

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final body = json.decode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;

      if (response.statusCode == 200) {
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
    } catch (e) {
      throw const AppError(
          statusCode: 0, message: 'Sin conexión al servidor.');
    }
  }
}