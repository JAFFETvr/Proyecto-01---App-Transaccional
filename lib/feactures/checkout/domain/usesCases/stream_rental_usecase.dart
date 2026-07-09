import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class StreamRentalUseCase {
  final RentalRepository _repository;
  const StreamRentalUseCase(this._repository);

  Stream<RentalEntity> execute(String id) {
    return _repository.streamRental(id);
  }
}
