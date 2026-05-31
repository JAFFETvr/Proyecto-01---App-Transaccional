import '../../../propietario/domain/entitie/tool.dart';
import '../../../propietario/data/datasoruce/tool_remote_data_source.dart';

class ToolRepositoryImpl {
  final ToolRemoteDataSourceImpl remoteDataSource;

  ToolRepositoryImpl({required this.remoteDataSource});

  Future<List<Tool>> getTools(String token) => remoteDataSource.getTools(token);
  Future<void> createTool(String token, Map<String, dynamic> data) => remoteDataSource.createTool(token, data);
  Future<void> updateTool(String token, String id, Map<String, dynamic> data) => remoteDataSource.updateTool(token, id, data);
  Future<void> deleteTool(String token, String id) => remoteDataSource.deleteTool(token, id);
}