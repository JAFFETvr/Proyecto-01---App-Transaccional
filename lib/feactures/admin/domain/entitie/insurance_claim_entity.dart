/// Lo que le debe el seguro de ToolShare al propietario tras ganar una
/// disputa (30% del valor estimado si la herramienta tenía seguro activo),
/// junto con sus datos bancarios registrados para transferirlo manualmente.
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
