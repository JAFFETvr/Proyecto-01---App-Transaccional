import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

/// Reconcilia el seguro sin payment_id: el backend lo busca en Mercado Pago
/// por external_reference (`ins:` + toolId). Respaldo para cuando el redirect
/// del checkout del seguro terminó en el navegador externo.
class ReconcileInsuranceUseCase {
  final ToolRepository _repository;
  const ReconcileInsuranceUseCase(this._repository);

  Future<ToolEntity> execute(String toolId) {
    return _repository.reconcileInsurance(toolId);
  }
}
