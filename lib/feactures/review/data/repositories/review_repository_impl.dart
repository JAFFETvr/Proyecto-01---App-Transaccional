import '../datasoruce/review_remote_datasource.dart';
import '../../domain/entitie/review_entity.dart';
import '../../domain/entitie/reviews_result_entity.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDatasource _datasource;
  ReviewRepositoryImpl(this._datasource);

  @override
  Future<ReviewEntity> submitReview({
    required String rentalId,
    required int rating,
    String? comment,
  }) =>
      _datasource.submitReview(rentalId: rentalId, rating: rating, comment: comment);

  @override
  Future<ReviewsResultEntity> getToolReviews(String toolId) =>
      _datasource.getToolReviews(toolId);

  @override
  Future<ReviewsResultEntity> getUserReviews(String userId) =>
      _datasource.getUserReviews(userId);
}
