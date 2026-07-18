import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class ConfirmInsurancePaymentUseCase {
  final ToolRepository _repository;
  const ConfirmInsurancePaymentUseCase(this._repository);

  Future<ToolEntity> execute(String toolId, String paymentId) {
    return _repository.confirmInsurancePayment(toolId, paymentId);
  }
}
