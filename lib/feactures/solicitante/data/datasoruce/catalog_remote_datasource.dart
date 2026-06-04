import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../shared/error/app_error.dart';
import '../../domain/entitie/tool_entity.dart';

class CatalogRemoteDatasource {
  static const _baseUrl = 'http://100.50.210.8:8080/api';

  Future<List<ToolEntity>> getTools({bool onlyAvailable = false}) async {
    try {
      final uri = Uri.parse('$_baseUrl/tools').replace(
        queryParameters: onlyAvailable ? {'available': 'true'} : null,
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
            name:        j['name']        as String,
            description: j['description'] as String? ?? '',
            category:    j['category']    as String? ?? '',
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