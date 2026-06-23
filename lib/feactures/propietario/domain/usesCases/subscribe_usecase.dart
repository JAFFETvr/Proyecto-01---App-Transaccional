import '../repositories/tool_repository.dart';

class SubscribeUseCase {
  final ToolRepository _repository;
  const SubscribeUseCase(this._repository);

  Future<bool> execute() {
    return _repository.subscribe();
  }
}
