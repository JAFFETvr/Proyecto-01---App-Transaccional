import '../data/datasoruce/bank_account_remote_datasource.dart';
import '../data/repositories/bank_account_repository_impl.dart';
import '../domain/repositories/bank_account_repository.dart';
import '../presentation/providers/bank_account_provider.dart';

class BankAccountDI {
  static final _datasource = BankAccountRemoteDatasource();
  static final BankAccountRepository _repository =
      BankAccountRepositoryImpl(_datasource);

  static BankAccountProvider provideBankAccountProvider() =>
      BankAccountProvider(repository: _repository);
}
