import '../repositories/tool_repository.dart';

class DeleteToolUseCase {
  final ToolRepository repository;

  DeleteToolUseCase(this.repository);

  Future<void> call(String token, String id) {
    return repository.deleteTool(token, id);
  }
}