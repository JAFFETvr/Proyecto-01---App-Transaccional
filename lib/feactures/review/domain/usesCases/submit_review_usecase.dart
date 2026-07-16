import '../entitie/review_entity.dart';
import '../repositories/review_repository.dart';

class SubmitReviewUseCase {
  final ReviewRepository _repository;
  const SubmitReviewUseCase(this._repository);

  Future<ReviewEntity> execute({
    required String rentalId,
    required int rating,
    String? comment,
  }) =>
      _repository.submitReview(rentalId: rentalId, rating: rating, comment: comment);
}
