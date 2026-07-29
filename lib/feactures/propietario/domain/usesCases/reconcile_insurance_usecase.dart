import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

/// Respaldo: reconcilia el seguro sin payment_id vía external_reference.
class ReconcileInsuranceUseCase {
  final ToolRepository _repository;
  const ReconcileInsuranceUseCase(this._repository);

  Future<ToolEntity> execute(String toolId) {
    return _repository.reconcileInsurance(toolId);
  }
}
