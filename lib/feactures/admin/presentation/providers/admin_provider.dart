import 'package:flutter/material.dart';

import '../../../../core/error/app_error.dart';
import '../../domain/entitie/admin_stats_entity.dart';
import '../../domain/usesCases/get_admin_stats_usecase.dart';
import '../../domain/usesCases/get_admin_rentals_usecase.dart';
import '../../domain/usesCases/resolve_dispute_usecase.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

class AdminProvider extends ChangeNotifier {
  final GetAdminStatsUseCase _getStats;
  final GetAdminRentalsUseCase _getRentals;
  final ResolveDisputeUseCase _resolveDispute;

  AdminProvider({
    required GetAdminStatsUseCase getStats,
    required GetAdminRentalsUseCase getRentals,
    required ResolveDisputeUseCase resolveDispute,
  }) : _getStats = getStats,
       _getRentals = getRentals,
       _resolveDispute = resolveDispute;

  AdminStatsEntity? _stats;
  List<RentalEntity> _rentals = [];
  bool _loading = false;
  String? _error;

  AdminStatsEntity? get stats => _stats;
  List<RentalEntity> get rentals => List.unmodifiable(_rentals);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchDashboardData({String? statusFilter}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getStats.execute(),
        _getRentals.execute(statusFilter: statusFilter),
      ]);
      _stats = results[0] as AdminStatsEntity;
      _rentals = results[1] as List<RentalEntity>;
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Error al cargar datos del administrador.';
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
    _error = null;
    notifyListeners();

    try {
      await _resolveDispute.execute(
        rentalId: rentalId,
        action: action,
        notes: notes,
      );
      await fetchDashboardData();
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Sin conexión al dictaminar la disputa.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
