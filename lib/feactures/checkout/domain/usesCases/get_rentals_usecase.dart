import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class GetRentalsUseCase {
  final RentalRepository _repository;
  const GetRentalsUseCase(this._repository);

  Future<List<RentalEntity>> execute() {
    return _repository.getRentals();
  }
}
