import '../repositories/rental_repository.dart';

class CancelRentalUseCase {
  final RentalRepository _repository;
  const CancelRentalUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.cancelRental(id);
  }
}
