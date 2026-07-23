import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class ConfirmPaymentUseCase {
  final RentalRepository _repository;
  const ConfirmPaymentUseCase(this._repository);

  Future<RentalEntity> execute(String rentalId, String paymentId) =>
      _repository.confirmPayment(rentalId, paymentId);
}
