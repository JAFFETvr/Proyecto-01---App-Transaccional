import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class DisputeRentalUseCase {
  final RentalRepository _repository;
  const DisputeRentalUseCase(this._repository);

  Future<RentalEntity> execute(String id, String reason) {
    return _repository.disputeRental(id, reason);
  }
}
