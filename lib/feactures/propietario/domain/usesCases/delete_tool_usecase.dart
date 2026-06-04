import '../repositories/tool_repository.dart';

class DeleteToolUseCase {
  final ToolRepository _repository;
  const DeleteToolUseCase(this._repository);

  Future<void> execute(String id) => _repository.deleteTool(id);
}