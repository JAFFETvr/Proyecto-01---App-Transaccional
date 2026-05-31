import '../entitie/tool.dart';
import '../repositories/tool_repository.dart';

class GetToolsUseCase {
  final ToolRepository repository;

  GetToolsUseCase(this.repository);

  Future<List<Tool>> call(String token) {
    return repository.getTools(token);
  }
}