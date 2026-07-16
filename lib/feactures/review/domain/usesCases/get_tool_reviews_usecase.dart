import '../entitie/reviews_result_entity.dart';
import '../repositories/review_repository.dart';

class GetToolReviewsUseCase {
  final ReviewRepository _repository;
  const GetToolReviewsUseCase(this._repository);

  Future<ReviewsResultEntity> execute(String toolId) => _repository.getToolReviews(toolId);
}
