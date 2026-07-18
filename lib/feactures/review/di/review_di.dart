import '../data/datasoruce/review_remote_datasource.dart';
import '../data/repositories/review_repository_impl.dart';
import '../domain/usesCases/submit_review_usecase.dart';
import '../domain/usesCases/get_tool_reviews_usecase.dart';
import '../domain/usesCases/get_user_reviews_usecase.dart';

class ReviewDI {
  static final _datasource = ReviewRemoteDatasource();
  static final _repository = ReviewRepositoryImpl(_datasource);

  static SubmitReviewUseCase provideSubmitReview() => SubmitReviewUseCase(_repository);
  static GetToolReviewsUseCase provideGetToolReviews() => GetToolReviewsUseCase(_repository);
  static GetUserReviewsUseCase provideGetUserReviews() => GetUserReviewsUseCase(_repository);
}
