import '../../domain/entitie/admin_stats_entity.dart';
import '../../domain/entitie/insurance_claim_entity.dart';
import '../../domain/entitie/resolve_dispute_result_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';
import '../datasoruce/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDatasource _datasource;

  AdminRepositoryImpl(this._datasource);

  @override
  Future<AdminStatsEntity> getStats() => _datasource.getStats();

  @override
  Future<List<RentalEntity>> getRentals({String? statusFilter}) =>
      _datasource.getRentals(statusFilter: statusFilter);

  @override
  Future<ResolveDisputeResultEntity> resolveDispute({
    required String rentalId,
    required String action,
    required String notes,
  }) => _datasource.resolveDispute(
    rentalId: rentalId,
    action: action,
    notes: notes,
  );

  @override
  Future<InsuranceClaimEntity> getInsuranceClaim(String rentalId) =>
      _datasource.getInsuranceClaim(rentalId);
}
