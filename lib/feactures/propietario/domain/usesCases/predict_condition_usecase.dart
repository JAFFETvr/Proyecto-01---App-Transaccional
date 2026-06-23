import 'dart:io';
import '../repositories/tool_repository.dart';

class PredictConditionUseCase {
  final ToolRepository _repository;
  const PredictConditionUseCase(this._repository);

  Future<Map<String, dynamic>> execute(File photo) {
    return _repository.predictCondition(photo);
  }
}
