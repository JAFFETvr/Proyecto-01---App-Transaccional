class CheckoutEntity {
  final String toolId;
  final String toolName;
  final int days;
  final double pricePerDay;
  final double total;
  final double deposit;

  const CheckoutEntity({
    required this.toolId,
    required this.toolName,
    required this.days,
    required this.pricePerDay,
    required this.total,
    required this.deposit,
  });
}
