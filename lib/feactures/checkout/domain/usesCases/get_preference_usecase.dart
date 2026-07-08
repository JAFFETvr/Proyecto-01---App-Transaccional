import '../repositories/rental_repository.dart';

class GetPreferenceUseCase {
  final RentalRepository _repository;
  const GetPreferenceUseCase(this._repository);

  Future<String> execute(String rentalId, String payerEmail) =>
      _repository.getPreference(rentalId, payerEmail);
}
