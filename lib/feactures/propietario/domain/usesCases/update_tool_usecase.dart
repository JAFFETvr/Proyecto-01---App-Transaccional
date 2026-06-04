import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class UpdateToolUseCase {
  final ToolRepository _repository;
  const UpdateToolUseCase(this._repository);

  Future<ToolEntity> execute({
    required String id,
    String? name,
    String? description,
    String? category,
    bool? isAvailable,
  }) {
    return _repository.updateTool(
      id: id, name: name, description: description,
      category: category, isAvailable: isAvailable,
    );
  }
}