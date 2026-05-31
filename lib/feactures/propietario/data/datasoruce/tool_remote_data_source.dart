import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../propietario/domain/entitie/tool.dart';

class ToolRemoteDataSourceImpl {
  final String baseUrl;

  ToolRemoteDataSourceImpl({required this.baseUrl});

  Future<List<Tool>> getTools(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tools'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Tool>.from(l.map((model) => Tool.fromJson(model)));
    } else {
      throw Exception('Error al cargar herramientas');
    }
  }

  Future<void> createTool(String token, Map<String, dynamic> toolData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tools'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(toolData),
    );
    if (response.statusCode != 201) throw Exception('Error al crear');
  }

  Future<void> updateTool(String token, String id, Map<String, dynamic> toolData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tools/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(toolData),
    );
    if (response.statusCode != 200) throw Exception('Error al actualizar');
  }

  Future<void> deleteTool(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tools/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Error al eliminar');
  }
}