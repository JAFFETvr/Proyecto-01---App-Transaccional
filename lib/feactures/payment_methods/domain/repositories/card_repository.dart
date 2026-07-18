import '../entitie/saved_card_entity.dart';

abstract class CardRepository {
  Future<String> getMpPublicKey();
  Future<List<SavedCardEntity>> getCards();
  Future<SavedCardEntity> addCard(String cardToken);
  Future<void> deleteCard(String cardId);
}
