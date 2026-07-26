import '../entitie/bank_account_entity.dart';

abstract class BankAccountRepository {
  Future<BankAccountEntity> getBankAccount();

  Future<BankAccountEntity> saveBankAccount({
    required String clabe,
    required String accountHolder,
    required String bankName,
  });

  Future<void> deleteBankAccount();
}
