import '../../domain/entitie/bank_account_entity.dart';
import '../../domain/repositories/bank_account_repository.dart';
import '../datasoruce/bank_account_remote_datasource.dart';

class BankAccountRepositoryImpl implements BankAccountRepository {
  final BankAccountRemoteDatasource _datasource;

  BankAccountRepositoryImpl(this._datasource);

  @override
  Future<BankAccountEntity> getBankAccount() => _datasource.getBankAccount();

  @override
  Future<BankAccountEntity> saveBankAccount({
    required String clabe,
    required String accountHolder,
    required String bankName,
  }) => _datasource.saveBankAccount(
    clabe: clabe,
    accountHolder: accountHolder,
    bankName: bankName,
  );

  @override
  Future<void> deleteBankAccount() => _datasource.deleteBankAccount();
}
