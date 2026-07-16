import '../entitie/review_entity.dart';
import '../entitie/reviews_result_entity.dart';

abstract class ReviewRepository {
  Future<ReviewEntity> submitReview({
    required String rentalId,
    required int rating,
    String? comment,
  });

  Future<ReviewsResultEntity> getToolReviews(String toolId);

  Future<ReviewsResultEntity> getUserReviews(String userId);
}
