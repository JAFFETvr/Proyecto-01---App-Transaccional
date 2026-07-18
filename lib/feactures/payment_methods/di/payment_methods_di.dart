import '../data/datasoruce/card_remote_datasource.dart';
import '../data/repositories/card_repository_impl.dart';
import '../domain/repositories/card_repository.dart';
import '../presentation/providers/card_provider.dart';

class PaymentMethodsDI {
  static final _datasource = CardRemoteDatasource();
  static final CardRepository _repository = CardRepositoryImpl(_datasource);

  static CardProvider provideCardProvider() =>
      CardProvider(repository: _repository, tokenizer: _datasource);
}
