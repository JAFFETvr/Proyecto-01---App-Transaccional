import '../entitie/review_entity.dart';
import '../entitie/reviews_result_entity.dart';

abstract class ReviewRepository {
  /// POST /rentals/{id}/review — el backend detecta automáticamente la
  /// dirección (owner califica al requester, requester califica la
  /// herramienta) según quién sea el autor autenticado.
  Future<ReviewEntity> submitReview({
    required String rentalId,
    required int rating,
    String? comment,
  });

  /// GET /tools/{id}/reviews (público)
  Future<ReviewsResultEntity> getToolReviews(String toolId);

  /// GET /users/{id}/reviews (requiere auth)
  Future<ReviewsResultEntity> getUserReviews(String userId);
}
