import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/error/app_error.dart';
import '../../../../../core/config/api_config.dart';
import '../../domain/entitie/user_entity.dart';

class RegisterRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String ine,
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
          'phone': phone,
          'ine': ine,
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
          isPro: user['is_pro'] as bool? ?? false,
          phone: user['phone'] as String? ?? '',
          ine:   user['ine']   as String? ?? '',
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

  Future<Map<String, dynamic>> verifyKyc({
    required String inePath,
    required String selfiePath,
    required String curp,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/verify-kyc');
      final req = http.MultipartRequest('POST', uri);
      req.files.add(await http.MultipartFile.fromPath('ine_image', inePath));
      req.files.add(await http.MultipartFile.fromPath('selfie_image', selfiePath));
      req.fields['curp'] = curp;

      final streamedRes = await req.send();
      final res = await http.Response.fromStream(streamedRes);

      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return body;
      }

      throw AppError(
        statusCode: res.statusCode,
        message: body['error'] as String? ?? 'La validación KYC fue rechazada.',
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(
        statusCode: 0,
        message: 'Sin conexión al servidor de visión KYC.',
      );
    }
  }
}