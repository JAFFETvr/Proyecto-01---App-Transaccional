import '../../domain/entitie/rental_entity.dart';
import '../../domain/entitie/message_entity.dart';
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
    String paymentMethod = 'card',
    String? cardToken,
    String? payerEmail,
  }) =>
      _datasource.createRental(
        toolId: toolId,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
        payerEmail: payerEmail,
      );

  @override
  Future<List<RentalEntity>> getRentals() => _datasource.getRentals();

  @override
  Future<RentalEntity> getRental(String id) => _datasource.getRental(id);

  @override
  Stream<RentalEntity> streamRental(String id) => _datasource.streamRental(id);

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

  @override
  Future<List<MessageEntity>> getMessages(String rentalId) => _datasource.getMessages(rentalId);

  @override
  Future<MessageEntity> sendMessage(String rentalId, String message) => _datasource.sendMessage(rentalId, message);

  @override
  Future<Map<String, dynamic>> verifyContract(String id) => _datasource.verifyContract(id);

  @override
  Future<String> getPreference(String rentalId, String payerEmail) =>
      _datasource.getPreference(rentalId, payerEmail);

  @override
  Future<RentalEntity> confirmPayment(String rentalId, String paymentId) =>
      _datasource.confirmPayment(rentalId, paymentId);

  @override
  Future<RentalEntity> reconcilePayment(String rentalId) =>
      _datasource.reconcilePayment(rentalId);
}
