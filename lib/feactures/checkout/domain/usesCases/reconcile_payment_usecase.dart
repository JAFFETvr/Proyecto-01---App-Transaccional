import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

/// Reconcilia el pago de una renta sin payment_id: el backend lo busca en
/// Mercado Pago por external_reference. Respaldo para cuando el redirect del
/// checkout terminó en el navegador externo y la app nunca lo interceptó.
class ReconcilePaymentUseCase {
  final RentalRepository _repository;
  const ReconcilePaymentUseCase(this._repository);

  Future<RentalEntity> execute(String rentalId) =>
      _repository.reconcilePayment(rentalId);
}
