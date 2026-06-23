import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class GetRentalUseCase {
  final RentalRepository _repository;
  const GetRentalUseCase(this._repository);

  Future<RentalEntity> execute(String id) {
    return _repository.getRental(id);
  }
}
