import '../repositories/admin_repository.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

class ResolveDisputeUseCase {
  final AdminRepository _repository;
  const ResolveDisputeUseCase(this._repository);

  Future<RentalEntity> execute({
    required String rentalId,
    required String action,
    required String notes,
  }) => _repository.resolveDispute(
    rentalId: rentalId,
    action: action,
    notes: notes,
  );
}
