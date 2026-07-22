class AdminStatsEntity {
  final int totalTools;
  final int totalRentals;
  final int activeRentals;
  final int disputedRentals;
  final double frozenFunds;

  const AdminStatsEntity({
    required this.totalTools,
    required this.totalRentals,
    required this.activeRentals,
    required this.disputedRentals,
    required this.frozenFunds,
  });
}
