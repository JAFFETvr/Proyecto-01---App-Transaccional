import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class CancelInsuranceUseCase {
  final ToolRepository _repository;
  const CancelInsuranceUseCase(this._repository);

  Future<ToolEntity> execute(String toolId) {
    return _repository.cancelInsurance(toolId);
  }
}
