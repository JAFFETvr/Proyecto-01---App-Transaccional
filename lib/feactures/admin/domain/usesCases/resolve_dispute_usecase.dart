import '../repositories/admin_repository.dart';
import '../entitie/resolve_dispute_result_entity.dart';

class ResolveDisputeUseCase {
  final AdminRepository _repository;
  const ResolveDisputeUseCase(this._repository);

  Future<ResolveDisputeResultEntity> execute({
    required String rentalId,
    required String action,
    required String notes,
  }) => _repository.resolveDispute(
    rentalId: rentalId,
    action: action,
    notes: notes,
  );
}
