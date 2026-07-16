import 'review_entity.dart';

class ReviewsResultEntity {
  final List<ReviewEntity> reviews;
  final double averageRating;
  final int reviewCount;

  const ReviewsResultEntity({
    required this.reviews,
    required this.averageRating,
    required this.reviewCount,
  });

  static const empty = ReviewsResultEntity(reviews: [], averageRating: 0, reviewCount: 0);
}
