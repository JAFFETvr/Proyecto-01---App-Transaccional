import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class CreateRentalUseCase {
  final RentalRepository _repository;
  const CreateRentalUseCase(this._repository);

  Future<RentalEntity> execute({
    required String toolId,
    required String startDate,
    required String endDate,
    String paymentMethod = 'card',
    String? cardToken,
    String? payerEmail,
  }) {
    return _repository.createRental(
      toolId: toolId,
      startDate: startDate,
      endDate: endDate,
      paymentMethod: paymentMethod,
      cardToken: cardToken,
      payerEmail: payerEmail,
    );
  }
}
