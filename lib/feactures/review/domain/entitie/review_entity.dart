class ReviewEntity {
  final String id;
  final String rentalId;
  final String authorId;
  final String targetType;
  final String targetId;
  final int rating;
  final String comment;
  final String createdAt;

  const ReviewEntity({
    required this.id,
    required this.rentalId,
    required this.authorId,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });
}
