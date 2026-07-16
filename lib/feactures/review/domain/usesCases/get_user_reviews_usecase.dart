import '../entitie/reviews_result_entity.dart';
import '../repositories/review_repository.dart';

class GetUserReviewsUseCase {
  final ReviewRepository _repository;
  const GetUserReviewsUseCase(this._repository);

  Future<ReviewsResultEntity> execute(String userId) => _repository.getUserReviews(userId);
}
