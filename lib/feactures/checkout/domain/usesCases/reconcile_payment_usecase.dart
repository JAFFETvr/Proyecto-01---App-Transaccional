import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

/// Reconcilia el pago sin payment_id, buscándolo en MP por external_reference.
class ReconcilePaymentUseCase {
  final RentalRepository _repository;
  const ReconcilePaymentUseCase(this._repository);

  Future<RentalEntity> execute(String rentalId) =>
      _repository.reconcilePayment(rentalId);
}
