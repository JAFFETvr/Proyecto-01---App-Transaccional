import '../repositories/tool_repository.dart';

class CreateToolUseCase {
  final ToolRepository repository;

  CreateToolUseCase(this.repository);

  Future<void> call(String token, Map<String, dynamic> toolData) {
    // Aquí podrías agregar validaciones de negocio puro antes de ir al repo
    return repository.createTool(token, toolData);
  }
}