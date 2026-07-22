import '../entitie/admin_stats_entity.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

abstract class AdminRepository {
  Future<AdminStatsEntity> getStats();

  Future<List<RentalEntity>> getRentals({String? statusFilter});

  Future<RentalEntity> resolveDispute({
    required String rentalId,
    required String action,
    required String notes,
  });
}
