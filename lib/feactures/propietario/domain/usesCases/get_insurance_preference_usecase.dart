import '../repositories/tool_repository.dart';

class GetInsurancePreferenceUseCase {
  final ToolRepository _repository;
  const GetInsurancePreferenceUseCase(this._repository);

  Future<String> execute(String toolId) {
    return _repository.getInsurancePreference(toolId);
  }
}
