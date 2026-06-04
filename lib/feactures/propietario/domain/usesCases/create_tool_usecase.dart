import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class CreateToolUseCase {
  final ToolRepository _repository;
  const CreateToolUseCase(this._repository);

  Future<ToolEntity> execute({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
  }) {
    return _repository.createTool(
      name: name, description: description,
      category: category, isAvailable: isAvailable,
    );
  }
}