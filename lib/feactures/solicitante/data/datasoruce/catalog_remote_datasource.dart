import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/error/app_error.dart';
import '../../../../../core/config/api_config.dart';
import '../../domain/entitie/tool_entity.dart';

class CatalogRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<List<ToolEntity>> getTools({bool onlyAvailable = false, String search = ''}) async {
    try {
      final queryParams = <String, String>{};
      if (onlyAvailable) queryParams['available'] = 'true';
      if (search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/tools').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final res = await http.get(uri,
          headers: {'Content-Type': 'application/json'});

      if (res.statusCode == 200) {
        final list = json.decode(utf8.decode(res.bodyBytes)) as List;
        return list.map((e) {
          final j = e as Map<String, dynamic>;
          return ToolEntity(
            id:          j['id']          as String,
            ownerId:     j['owner_id']    as String,
            ownerName:   j['owner_name']  as String? ?? '',
            name:        j['name']        as String,
            description: j['description'] as String? ?? '',
            category:    j['category']    as String? ?? '',
            photoUrl:    j['photo_url']   as String? ?? '',
            estimatedValue: (j['estimated_value'] as num?)?.toDouble() ?? 0.0,
            dailyRate:      (j['daily_rate']      as num?)?.toDouble() ?? 0.0,
            suggestedMinDailyRate: (j['suggested_min_daily_rate'] as num?)?.toDouble() ?? 0.0,
            latitude:       (j['latitude']        as num?)?.toDouble() ?? 0.0,
            longitude:      (j['longitude']       as num?)?.toDouble() ?? 0.0,
            isAvailable: j['is_available'] as bool,
            createdAt:   j['created_at']  as String,
            updatedAt:   j['updated_at']  as String,
          );
        }).toList();
      }

      final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      throw AppError(
        statusCode: res.statusCode,
        message: body['error'] as String? ?? 'Error del servidor',
      );
    } on AppError { rethrow; }
    catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión al servidor.');
    }
  }
}