import '../../domain/entitie/rental_entity.dart';
import '../../domain/repositories/rental_repository.dart';
import '../datasoruce/rental_remote_datasource.dart';

class RentalRepositoryImpl implements RentalRepository {
  final RentalRemoteDatasource _datasource;

  const RentalRepositoryImpl(this._datasource);

  @override
  Future<RentalEntity> createRental({
    required String toolId,
    required String startDate,
    required String endDate,
    String? cardToken,
    String? payerEmail,
  }) =>
      _datasource.createRental(
        toolId: toolId,
        startDate: startDate,
        endDate: endDate,
        cardToken: cardToken,
        payerEmail: payerEmail,
      );

  @override
  Future<List<RentalEntity>> getRentals() => _datasource.getRentals();

  @override
  Future<RentalEntity> getRental(String id) => _datasource.getRental(id);

  @override
  Future<RentalEntity> confirmDelivery(
    String id, {
    double? latitude,
    double? longitude,
  }) =>
      _datasource.confirmDelivery(id, latitude: latitude, longitude: longitude);

  @override
  Future<RentalEntity> confirmReturn(String id) => _datasource.confirmReturn(id);

  @override
  Future<RentalEntity> disputeRental(String id, String reason) =>
      _datasource.disputeRental(id, reason);

  @override
  Future<void> cancelRental(String id) => _datasource.cancelRental(id);
}
