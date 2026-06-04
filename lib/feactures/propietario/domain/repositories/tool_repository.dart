import '../entitie/tool_entity.dart';

abstract class ToolRepository {
  Future<List<ToolEntity>> getTools();
  Future<ToolEntity> createTool({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
  });
  Future<ToolEntity> updateTool({
    required String id,
    String? name,
    String? description,
    String? category,
    bool? isAvailable,
  });
  Future<void> deleteTool(String id);
}