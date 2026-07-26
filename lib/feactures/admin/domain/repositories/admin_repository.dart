import '../entitie/admin_stats_entity.dart';
import '../entitie/insurance_claim_entity.dart';
import '../entitie/resolve_dispute_result_entity.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

abstract class AdminRepository {
  Future<AdminStatsEntity> getStats();

  Future<List<RentalEntity>> getRentals({String? statusFilter});

  Future<ResolveDisputeResultEntity> resolveDispute({
    required String rentalId,
    required String action,
    required String notes,
  });

  /// Consulta el pago de seguro pendiente al propietario de una renta.
  /// Devuelve un claim vacío (amount: 0) si la herramienta no tenía seguro
  /// activo.
  Future<InsuranceClaimEntity> getInsuranceClaim(String rentalId);
}
