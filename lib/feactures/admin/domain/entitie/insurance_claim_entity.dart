/// Pago de seguro (30% del valor estimado) al propietario tras ganar disputa.
class InsuranceClaimEntity {
  final double amount;
  final String bankClabe;
  final String bankAccountHolder;
  final String bankName;
  final bool bankAccountRegistered;

  const InsuranceClaimEntity({
    required this.amount,
    required this.bankClabe,
    required this.bankAccountHolder,
    required this.bankName,
    required this.bankAccountRegistered,
  });
}
