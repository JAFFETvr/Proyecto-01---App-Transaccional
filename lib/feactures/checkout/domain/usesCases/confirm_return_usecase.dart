import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class ConfirmReturnUseCase {
  final RentalRepository _repository;
  const ConfirmReturnUseCase(this._repository);

  Future<RentalEntity> execute(String id) {
    return _repository.confirmReturn(id);
  }
}
