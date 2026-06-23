import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/error/app_error.dart';
import '../../../../../shared/config/api_config.dart';
import '../../domain/entitie/rental_entity.dart';

class RentalRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  RentalEntity _fromJson(Map<String, dynamic> j) => RentalEntity(
        id:                         j['id'] as String,
        toolId:                     j['tool_id'] as String,
        requesterId:                j['requester_id'] as String,
        ownerId:                    j['owner_id'] as String,
        startDate:                  j['start_date'] as String,
        endDate:                    j['end_date'] as String,
        dailyRate:                  (j['daily_rate'] as num?)?.toDouble() ?? 0.0,
        totalAmount:                (j['total_amount'] as num?)?.toDouble() ?? 0.0,
        status:                     j['status'] as String,
        mpPaymentId:                j['mp_payment_id'] as String? ?? '',
        paymentStatus:              j['payment_status'] as String? ?? '',
        deductibleAmount:           (j['deductible_amount'] as num?)?.toDouble() ?? 0.0,
        ownerConfirmedDelivery:     j['owner_confirmed_delivery'] as bool? ?? false,
        requesterConfirmedDelivery: j['requester_confirmed_delivery'] as bool? ?? false,
        contractHash:               j['contract_hash'] as String? ?? '',
        deliveryLat:                (j['delivery_lat'] as num?)?.toDouble() ?? 0.0,
        deliveryLng:                (j['delivery_lng'] as num?)?.toDouble() ?? 0.0,
        deliveryAt:                 j['delivery_at'] as String? ?? '',
        requesterConfirmedReturn:   j['requester_confirmed_return'] as bool? ?? false,
        ownerConfirmedReturn:       j['owner_confirmed_return'] as bool? ?? false,
        disputeReason:              j['dispute_reason'] as String? ?? '',
        createdAt:                  j['created_at'] as String,
        updatedAt:                  j['updated_at'] as String,
      );

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg  = (body is Map && body['error'] != null)
        ? body['error'] as String : 'Error del servidor transaccional';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  Future<RentalEntity> createRental({
    required String toolId,
    required String startDate,
    required String endDate,
    String? cardToken,
    String? payerEmail,
  }) async {
    try {
      final headers = await _authHeaders;
      final body = <String, dynamic>{
        'tool_id': toolId,
        'start_date': startDate,
        'end_date': endDate,
      };
      if (cardToken != null) {
        body['card_token'] = cardToken;
      }
      if (payerEmail != null) {
        body['payer_email'] = payerEmail;
      }

      final res = await http.post(
        Uri.parse('$_baseUrl/rentals'),
        headers: headers,
        body: json.encode(body),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<List<RentalEntity>> getRentals() async {
    try {
      final headers = await _authHeaders;
      final res = await http.get(Uri.parse('$_baseUrl/rentals'), headers: headers);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<RentalEntity> getRental(String id) async {
    try {
      final headers = await _authHeaders;
      final res = await http.get(Uri.parse('$_baseUrl/rentals/$id'), headers: headers);
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<RentalEntity> confirmDelivery(
    String id, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final headers = await _authHeaders;
      final body = <String, dynamic>{};
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$id/confirm-delivery'),
        headers: headers,
        body: json.encode(body),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<RentalEntity> confirmReturn(String id) async {
    try {
      final headers = await _authHeaders;
      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$id/confirm-return'),
        headers: headers,
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<RentalEntity> disputeRental(String id, String reason) async {
    try {
      final headers = await _authHeaders;
      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$id/dispute'),
        headers: headers,
        body: json.encode({'reason': reason}),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<void> cancelRental(String id) async {
    try {
      final headers = await _authHeaders;
      final res = await http.delete(
        Uri.parse('$_baseUrl/rentals/$id'),
        headers: headers,
      );
      _throwIfError(res);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }
}
