import '../entitie/tool.dart';

abstract class ToolRepository {
  Future<List<Tool>> getTools(String token);
  Future<void> createTool(String token, Map<String, dynamic> data);
  Future<void> updateTool(String token, String id, Map<String, dynamic> data);
  Future<void> deleteTool(String token, String id);
}