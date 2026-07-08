import '../entitie/rental_entity.dart';
import '../entitie/message_entity.dart';

abstract class RentalRepository {
  Future<RentalEntity> createRental({
    required String toolId,
    required String startDate,
    required String endDate,
    String paymentMethod = 'card',
    String? cardToken,
    String? payerEmail,
  });

  Future<List<RentalEntity>> getRentals();

  Future<RentalEntity> getRental(String id);

  Future<RentalEntity> confirmDelivery(
    String id, {
    double? latitude,
    double? longitude,
  });

  Future<RentalEntity> confirmReturn(String id);

  Future<RentalEntity> disputeRental(String id, String reason);

  Future<void> cancelRental(String id);

  Future<List<MessageEntity>> getMessages(String rentalId);

  Future<MessageEntity> sendMessage(String rentalId, String message);

  Future<String> getPreference(String rentalId, String payerEmail);
}
