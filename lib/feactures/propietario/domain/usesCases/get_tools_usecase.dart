import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class GetToolsUseCase {
  final ToolRepository _repository;
  const GetToolsUseCase(this._repository);

  Future<List<ToolEntity>> execute() => _repository.getTools();
}