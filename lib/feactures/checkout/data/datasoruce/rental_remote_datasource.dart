import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/error/app_error.dart';
import '../../../../../shared/config/api_config.dart';
import '../../domain/entitie/rental_entity.dart';
import '../../domain/entitie/message_entity.dart';

class RentalRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    var deviceId = prefs.getString('device_id') ?? '';
    if (deviceId.isEmpty) {
      deviceId = 'dev-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', deviceId);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Device-ID': deviceId,
    };
  }

  RentalEntity _fromJson(Map<String, dynamic> j) => RentalEntity(
        id:                         j['id'] as String,
        toolId:                     j['tool_id'] as String,
        requesterId:                j['requester_id'] as String,
        ownerId:                    j['owner_id'] as String,
        ownerName:                  j['owner_name'] as String? ?? '',
        requesterName:              j['requester_name'] as String? ?? '',
        startDate:                  j['start_date'] as String,
        endDate:                    j['end_date'] as String,
        dailyRate:                  (j['daily_rate'] as num?)?.toDouble() ?? 0.0,
        totalAmount:                (j['total_amount'] as num?)?.toDouble() ?? 0.0,
        status:                     j['status'] as String,
        paymentMethod:              j['payment_method'] as String? ?? 'card',
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
    String paymentMethod = 'card',
    String? cardToken,
    String? payerEmail,
  }) async {
    try {
      final headers = await _authHeaders;
      final body = <String, dynamic>{
        'tool_id': toolId,
        'start_date': startDate,
        'end_date': endDate,
        'payment_method': paymentMethod,
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

  Stream<RentalEntity> streamRental(String id) async* {
    final client = http.Client();
    try {
      final headers = await _authHeaders;
      final request = http.Request('GET', Uri.parse('$_baseUrl/rentals/$id/stream'));
      request.headers.addAll(headers);

      final response = await client.send(request);
      if (response.statusCode >= 400) {
        throw const AppError(statusCode: 0, message: 'Error de conexión con el stream.');
      }

      final streamLines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in streamLines) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr.isNotEmpty && dataStr != 'keep-alive') {
            final data = json.decode(dataStr) as Map<String, dynamic>;
            yield _fromJson(data);
          }
        }
      }
    } catch (_) {
      client.close();
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    } finally {
      client.close();
    }
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

  Future<List<MessageEntity>> getMessages(String rentalId) async {
    try {
      final headers = await _authHeaders;
      final res = await http.get(Uri.parse('$_baseUrl/rentals/$rentalId/messages'), headers: headers);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => MessageEntity.fromJson(e as Map<String, dynamic>)).toList();
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<MessageEntity> sendMessage(String rentalId, String message) async {
    try {
      final headers = await _authHeaders;
      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$rentalId/messages'),
        headers: headers,
        body: json.encode({'message': message}),
      );
      _throwIfError(res);
      return MessageEntity.fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<String> getPreference(String rentalId, String payerEmail) async {
    try {
      final headers = await _authHeaders;
      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$rentalId/preference'),
        headers: headers,
        body: json.encode({'payer_email': payerEmail}),
      );
      _throwIfError(res);
      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return body['init_point'] as String;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<Map<String, dynamic>> verifyContract(String id) async {
    try {
      final headers = await _authHeaders;
      final res = await http.get(
        Uri.parse('$_baseUrl/rentals/$id/verify-contract'),
        headers: headers,
      );
      _throwIfError(res);
      return json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }
}
