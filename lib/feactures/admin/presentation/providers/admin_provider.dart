import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/config/api_config.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

class AdminStats {
  final int totalTools;
  final int totalRentals;
  final int activeRentals;
  final int disputedRentals;
  final double frozenFunds;

  const AdminStats({
    required this.totalTools,
    required this.totalRentals,
    required this.activeRentals,
    required this.disputedRentals,
    required this.frozenFunds,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalTools:      (j['total_tools'] as num?)?.toInt() ?? 0,
        totalRentals:    (j['total_rentals'] as num?)?.toInt() ?? 0,
        activeRentals:   (j['active_rentals'] as num?)?.toInt() ?? 0,
        disputedRentals: (j['disputed_rentals'] as num?)?.toInt() ?? 0,
        frozenFunds:     (j['frozen_funds'] as num?)?.toDouble() ?? 0.0,
      );
}

class AdminProvider extends ChangeNotifier {
  AdminStats? _stats;
  List<RentalEntity> _rentals = [];
  bool _loading = false;
  String? _error;

  AdminStats? get stats => _stats;
  List<RentalEntity> get rentals => List.unmodifiable(_rentals);
  bool get loading => _loading;
  String? get error => _error;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  RentalEntity _rentalFromJson(Map<String, dynamic> j) => RentalEntity(
        id:                         j['id'] as String? ?? '',
        toolId:                     j['tool_id'] as String? ?? '',
        requesterId:                j['requester_id'] as String? ?? '',
        ownerId:                    j['owner_id'] as String? ?? '',
        startDate:                  j['start_date'] as String? ?? '',
        endDate:                    j['end_date'] as String? ?? '',
        dailyRate:                  (j['daily_rate'] as num?)?.toDouble() ?? 0.0,
        totalAmount:                (j['total_amount'] as num?)?.toDouble() ?? 0.0,
        status:                     j['status'] as String? ?? '',
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
        createdAt:                  j['created_at'] as String? ?? '',
        updatedAt:                  j['updated_at'] as String? ?? '',
      );

  Future<void> fetchDashboardData({String? statusFilter}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final headers = await _authHeaders;
      final statsRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/admin/stats'), headers: headers);
      if (statsRes.statusCode == 200) {
        _stats = AdminStats.fromJson(jsonDecode(statsRes.body));
      }

      var rentalsUrl = '${ApiConfig.baseUrl}/admin/rentals';
      if (statusFilter != null && statusFilter.isNotEmpty) {
        rentalsUrl += '?status=$statusFilter';
      }
      final rentalsRes = await http.get(Uri.parse(rentalsUrl), headers: headers);
      if (rentalsRes.statusCode == 200) {
        final list = jsonDecode(rentalsRes.body) as List;
        _rentals = list.map((e) => _rentalFromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _error = 'Error al cargar datos del administrador';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resolveDispute({
    required String rentalId,
    required String action,
    required String notes,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final headers = await _authHeaders;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/rentals/$rentalId/resolve'),
        headers: headers,
        body: jsonEncode({
          'action': action,
          'notes': notes,
        }),
      );

      if (res.statusCode == 200) {
        await fetchDashboardData();
        return true;
      } else {
        _error = 'Error al resolver la disputa: ${res.body}';
        return false;
      }
    } catch (e) {
      _error = 'Error de conexión al resolver disputa';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
