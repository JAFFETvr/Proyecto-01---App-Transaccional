import '../../domain/entitie/saved_card_entity.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasoruce/card_remote_datasource.dart';

class CardRepositoryImpl implements CardRepository {
  final CardRemoteDatasource _datasource;
  const CardRepositoryImpl(this._datasource);

  @override
  Future<String> getMpPublicKey() => _datasource.getMpPublicKey();

  @override
  Future<List<SavedCardEntity>> getCards() => _datasource.getCards();

  @override
  Future<SavedCardEntity> addCard(String cardToken) => _datasource.addCard(cardToken);

  @override
  Future<void> deleteCard(String cardId) => _datasource.deleteCard(cardId);
}
