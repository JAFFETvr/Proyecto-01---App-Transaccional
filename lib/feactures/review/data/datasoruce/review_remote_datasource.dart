import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../core/config/api_config.dart';
import '../../domain/entitie/review_entity.dart';
import '../../domain/entitie/reviews_result_entity.dart';

class ReviewRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  ReviewEntity _fromJson(Map<String, dynamic> j) => ReviewEntity(
        id:         j['id']          as String,
        rentalId:   j['rental_id']   as String,
        authorId:   j['author_id']   as String,
        targetType: j['target_type'] as String,
        targetId:   j['target_id']   as String,
        rating:     (j['rating'] as num).toInt(),
        comment:    j['comment'] as String? ?? '',
        createdAt:  j['created_at'] as String,
      );

  ReviewsResultEntity _resultFromJson(Map<String, dynamic> j) {
    final list = (j['reviews'] as List? ?? [])
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList();
    return ReviewsResultEntity(
      reviews: list,
      averageRating: (j['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Error del servidor';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  Future<ReviewEntity> submitReview({
    required String rentalId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/rentals/$rentalId/review'),
        headers: await _authHeaders,
        body: json.encode({
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        }),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ReviewsResultEntity> getToolReviews(String toolId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/tools/$toolId/reviews'));
      _throwIfError(res);
      return _resultFromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }

  Future<ReviewsResultEntity> getUserReviews(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/users/$userId/reviews'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      return _resultFromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError { rethrow; }
    catch (_) { throw const AppError(statusCode: 0, message: 'Sin conexión.'); }
  }
}
