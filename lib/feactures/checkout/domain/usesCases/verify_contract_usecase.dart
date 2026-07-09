import '../repositories/rental_repository.dart';

class VerifyContractUseCase {
  final RentalRepository _repository;
  const VerifyContractUseCase(this._repository);

  Future<Map<String, dynamic>> execute(String id) {
    return _repository.verifyContract(id);
  }
}
