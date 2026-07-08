import '../repositories/tool_repository.dart';

class GetSubscriptionPreferenceUseCase {
  final ToolRepository _repository;
  const GetSubscriptionPreferenceUseCase(this._repository);

  Future<String> execute() {
    return _repository.getSubscriptionPreference();
  }
}

class ConfirmSubscriptionPaymentUseCase {
  final ToolRepository _repository;
  const ConfirmSubscriptionPaymentUseCase(this._repository);

  Future<bool> execute(String paymentId) {
    return _repository.confirmSubscriptionPayment(paymentId);
  }
}

class RefreshIsProUseCase {
  final ToolRepository _repository;
  const RefreshIsProUseCase(this._repository);

  Future<bool> execute() {
    return _repository.refreshIsPro();
  }
}
