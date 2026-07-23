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

  // La verificación KYC puede tardar 15-20+ segundos (Haar Cascade + arranque
  // en frío del worker de PaddleOCR + ArcFace) — una sola petición HTTP tan
  // larga corría el riesgo de que algún proxy intermedio (Railway) la
  // cortara a medias aunque el servidor sí hubiera terminado bien
  // (confirmado en producción: el log de Go mostraba 200 OK mientras la app
  // ya había mostrado el rechazo). Ahora el POST arranca la verificación en
  // segundo plano y responde de inmediato con un job_id; aquí se pregunta
  // el estatus cada 2s hasta que termine.
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
      final startRes = await http.Response.fromStream(streamedRes);
      final startBody =
          json.decode(utf8.decode(startRes.bodyBytes)) as Map<String, dynamic>;

      if (startRes.statusCode != 202) {
        throw AppError(
          statusCode: startRes.statusCode,
          message:
              startBody['error'] as String? ?? 'La validación KYC fue rechazada.',
        );
      }
      final jobId = startBody['job_id'] as String;

      // 60 intentos x 2s = 120s máximo, igual al timeout que Go ya usa para
      // esta misma operación.
      for (var intento = 0; intento < 60; intento++) {
        await Future.delayed(const Duration(seconds: 2));

        final statusRes =
            await http.get(Uri.parse('$_baseUrl/auth/verify-kyc/$jobId'));
        final statusBody =
            json.decode(utf8.decode(statusRes.bodyBytes)) as Map<String, dynamic>;

        if (statusBody['status'] == 'processing') continue;

        if (statusBody['status'] == 'done') {
          return statusBody;
        }

        throw AppError(
          statusCode: statusRes.statusCode,
          message: statusBody['error'] as String? ??
              'La validación KYC fue rechazada.',
        );
      }

      throw const AppError(
        statusCode: 0,
        message: 'La verificación KYC tardó demasiado. Intenta de nuevo.',
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