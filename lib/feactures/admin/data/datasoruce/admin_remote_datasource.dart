import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/app_error.dart';
import '../../../../../core/config/api_config.dart';
import '../../domain/entitie/admin_stats_entity.dart';
import '../../domain/entitie/insurance_claim_entity.dart';
import '../../domain/entitie/resolve_dispute_result_entity.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

class AdminRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  AdminStatsEntity _statsFromJson(Map<String, dynamic> j) => AdminStatsEntity(
    totalTools: (j['total_tools'] as num?)?.toInt() ?? 0,
    totalRentals: (j['total_rentals'] as num?)?.toInt() ?? 0,
    activeRentals: (j['active_rentals'] as num?)?.toInt() ?? 0,
    disputedRentals: (j['disputed_rentals'] as num?)?.toInt() ?? 0,
    frozenFunds: (j['frozen_funds'] as num?)?.toDouble() ?? 0.0,
  );

  RentalEntity _rentalFromJson(Map<String, dynamic> j) => RentalEntity(
    id: j['id'] as String? ?? '',
    toolId: j['tool_id'] as String? ?? '',
    requesterId: j['requester_id'] as String? ?? '',
    ownerId: j['owner_id'] as String? ?? '',
    ownerName: j['owner_name'] as String? ?? '',
    requesterName: j['requester_name'] as String? ?? '',
    startDate: j['start_date'] as String? ?? '',
    endDate: j['end_date'] as String? ?? '',
    dailyRate: (j['daily_rate'] as num?)?.toDouble() ?? 0.0,
    totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0.0,
    status: j['status'] as String? ?? '',
    paymentMethod: j['payment_method'] as String? ?? 'card',
    mpPaymentId: j['mp_payment_id'] as String? ?? '',
    paymentStatus: j['payment_status'] as String? ?? '',
    deductibleAmount: (j['deductible_amount'] as num?)?.toDouble() ?? 0.0,
    commissionAmount: (j['commission_amount'] as num?)?.toDouble() ?? 0.0,
    ownerConfirmedDelivery: j['owner_confirmed_delivery'] as bool? ?? false,
    requesterConfirmedDelivery:
        j['requester_confirmed_delivery'] as bool? ?? false,
    contractHash: j['contract_hash'] as String? ?? '',
    deliveryLat: (j['delivery_lat'] as num?)?.toDouble() ?? 0.0,
    deliveryLng: (j['delivery_lng'] as num?)?.toDouble() ?? 0.0,
    deliveryAt: j['delivery_at'] as String? ?? '',
    requesterConfirmedReturn: j['requester_confirmed_return'] as bool? ?? false,
    ownerConfirmedReturn: j['owner_confirmed_return'] as bool? ?? false,
    disputeReason: j['dispute_reason'] as String? ?? '',
    createdAt: j['created_at'] as String? ?? '',
    updatedAt: j['updated_at'] as String? ?? '',
  );

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Error del servidor';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  Future<AdminStatsEntity> getStats() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      return _statsFromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<List<RentalEntity>> getRentals({String? statusFilter}) async {
    try {
      var url = '$_baseUrl/admin/rentals';
      if (statusFilter != null && statusFilter.isNotEmpty) {
        url += '?status=$statusFilter';
      }
      final res = await http.get(Uri.parse(url), headers: await _authHeaders);
      _throwIfError(res);
      final list = json.decode(utf8.decode(res.bodyBytes)) as List;
      return list
          .map((e) => _rentalFromJson(e as Map<String, dynamic>))
          .toList();
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<ResolveDisputeResultEntity> resolveDispute({
    required String rentalId,
    required String action,
    required String notes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin/rentals/$rentalId/resolve'),
        headers: await _authHeaders,
        body: json.encode({'action': action, 'notes': notes}),
      );
      _throwIfError(res);
      final body =
          json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final rental = _rentalFromJson(body['rental'] as Map<String, dynamic>);
      final claimJson = body['insurance_claim'] as Map<String, dynamic>?;
      return ResolveDisputeResultEntity(
        rental: rental,
        insuranceClaim: claimJson == null
            ? null
            : InsuranceClaimEntity(
                amount: (claimJson['amount'] as num?)?.toDouble() ?? 0.0,
                bankClabe: claimJson['bank_clabe'] as String? ?? '',
                bankAccountHolder:
                    claimJson['bank_account_holder'] as String? ?? '',
                bankName: claimJson['bank_name'] as String? ?? '',
                bankAccountRegistered:
                    claimJson['bank_account_registered'] as bool? ?? false,
              ),
      );
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }
}
