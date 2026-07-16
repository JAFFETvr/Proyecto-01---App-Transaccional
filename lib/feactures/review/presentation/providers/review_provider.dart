import 'package:flutter/material.dart';

import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/reviews_result_entity.dart';
import '../../domain/usesCases/submit_review_usecase.dart';
import '../../domain/usesCases/get_tool_reviews_usecase.dart';
import '../../domain/usesCases/get_user_reviews_usecase.dart';

class ReviewProvider extends ChangeNotifier {
  final SubmitReviewUseCase _submitReview;
  final GetToolReviewsUseCase _getToolReviews;
  final GetUserReviewsUseCase _getUserReviews;

  ReviewProvider({
    required SubmitReviewUseCase submitReview,
    required GetToolReviewsUseCase getToolReviews,
    required GetUserReviewsUseCase getUserReviews,
  })  : _submitReview = submitReview,
        _getToolReviews = getToolReviews,
        _getUserReviews = getUserReviews;

  bool _loading = false;
  bool _submitting = false;
  String? _error;
  ReviewsResultEntity _toolReviews = ReviewsResultEntity.empty;

  final Set<String> _reviewedKeys = {};
  String _key(String rentalId, String role) => '$rentalId:$role';

  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  ReviewsResultEntity get toolReviews => _toolReviews;
  bool hasReviewed(String rentalId, {required String role}) =>
      _reviewedKeys.contains(_key(rentalId, role));

  Future<void> fetchToolReviews(String toolId) async {
    _loading = true;
    notifyListeners();
    try {
      _toolReviews = await _getToolReviews.execute(toolId);
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserReviews(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      await _getUserReviews.execute(userId);
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview({
    required String rentalId,
    required String role,
    required int rating,
    String? comment,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      await _submitReview.execute(rentalId: rentalId, rating: rating, comment: comment);
      _reviewedKeys.add(_key(rentalId, role));
      return true;
    } on AppError catch (e) {
      if (e.statusCode == 409) _reviewedKeys.add(_key(rentalId, role));
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al enviar la reseña.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
