class SavedCardEntity {
  final String id;
  final String cardBrand;
  final String lastFourDigits;
  final int expirationMonth;
  final int expirationYear;
  final String createdAt;

  const SavedCardEntity({
    required this.id,
    required this.cardBrand,
    required this.lastFourDigits,
    required this.expirationMonth,
    required this.expirationYear,
    required this.createdAt,
  });
}
