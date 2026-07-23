class BankAccountEntity {
  final String clabe;
  final String accountHolder;
  final String bankName;
  final bool registered;

  const BankAccountEntity({
    required this.clabe,
    required this.accountHolder,
    required this.bankName,
    required this.registered,
  });
}
