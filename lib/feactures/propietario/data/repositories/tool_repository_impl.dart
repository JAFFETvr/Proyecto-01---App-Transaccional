import '../../domain/entitie/tool_entity.dart';
import '../../domain/repositories/tool_repository.dart';
import '../datasoruce/tool_remote_datasource.dart';

class ToolRepositoryImpl implements ToolRepository {
  final ToolRemoteDatasource _datasource;
  const ToolRepositoryImpl(this._datasource);

  @override Future<List<ToolEntity>> getTools() =>
      _datasource.getTools();

  @override Future<ToolEntity> createTool({
    required String name, required String description,
    required String category, required bool isAvailable,
  }) => _datasource.createTool(
        name: name, description: description,
        category: category, isAvailable: isAvailable);

  @override Future<ToolEntity> updateTool({
    required String id, String? name, String? description,
    String? category, bool? isAvailable,
  }) => _datasource.updateTool(
        id: id, name: name, description: description,
        category: category, isAvailable: isAvailable);

  @override Future<void> deleteTool(String id) =>
      _datasource.deleteTool(id);
}