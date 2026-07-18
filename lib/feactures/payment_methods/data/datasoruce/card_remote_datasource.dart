import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entitie/saved_card_entity.dart';

class CardRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;
  static const _mpTokenUrl = 'https://api.mercadopago.com/v1/card_tokens';

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

  SavedCardEntity _fromJson(Map<String, dynamic> j) => SavedCardEntity(
        id: j['id'] as String,
        cardBrand: j['card_brand'] as String? ?? '',
        lastFourDigits: j['last_four_digits'] as String? ?? '',
        expirationMonth: j['expiration_month'] as int? ?? 0,
        expirationYear: j['expiration_year'] as int? ?? 0,
        createdAt: j['created_at'] as String? ?? '',
      );

  Future<String> getMpPublicKey() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/config'));
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['mp_public_key'] as String? ?? '';
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  /// Tokeniza los datos de la tarjeta directamente contra Mercado Pago (no
  /// pasan por nuestro backend). El resultado es un token de un solo uso que
  /// sí se envía al backend para guardar la tarjeta.
  Future<String> tokenizeCard({
    required String publicKey,
    required String cardNumber,
    required String cardholderName,
    required int expirationMonth,
    required int expirationYear,
    required String securityCode,
  }) async {
    try {
      final uri = Uri.parse('$_mpTokenUrl?public_key=$publicKey');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'card_number': cardNumber,
          'expiration_month': expirationMonth,
          'expiration_year': expirationYear,
          'security_code': securityCode,
          'cardholder': {'name': cardholderName},
        }),
      );
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (res.statusCode >= 400 || body['id'] == null) {
        final msg = body['message'] as String? ?? 'Mercado Pago rechazó la tarjeta';
        throw AppError(statusCode: res.statusCode, message: msg);
      }
      return body['id'] as String;
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'No se pudo validar la tarjeta con Mercado Pago.');
    }
  }

  Future<List<SavedCardEntity>> getCards() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/cards'), headers: await _authHeaders);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<SavedCardEntity> addCard(String cardToken) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/cards'),
        headers: await _authHeaders,
        body: json.encode({'card_token': cardToken}),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/auth/cards/$cardId'), headers: await _authHeaders);
      _throwIfError(res);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }
}
