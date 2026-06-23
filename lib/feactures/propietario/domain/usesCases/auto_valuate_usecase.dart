import '../repositories/tool_repository.dart';

class AutoValuateUseCase {
  final ToolRepository _repository;
  const AutoValuateUseCase(this._repository);

  Future<Map<String, dynamic>> execute({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
  }) {
    return _repository.autoValuate(
      name: name,
      scoreCondicion: scoreCondicion,
      category: category,
      brand: brand,
    );
  }
}
