import '../entitie/rental_entity.dart';
import '../repositories/rental_repository.dart';

class ConfirmDeliveryUseCase {
  final RentalRepository _repository;
  const ConfirmDeliveryUseCase(this._repository);

  Future<RentalEntity> execute(
    String id, {
    double? latitude,
    double? longitude,
  }) {
    return _repository.confirmDelivery(
      id,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
