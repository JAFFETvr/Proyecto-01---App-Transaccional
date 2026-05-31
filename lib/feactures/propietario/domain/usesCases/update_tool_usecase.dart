import '../repositories/tool_repository.dart';

class UpdateToolUseCase {
  final ToolRepository repository;

  UpdateToolUseCase(this.repository);

  Future<void> call(String token, String id, Map<String, dynamic> toolData) {
    return repository.updateTool(token, id, toolData);
  }
}