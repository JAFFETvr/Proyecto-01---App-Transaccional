import '../repositories/tool_repository.dart';

class GetPricingSuggestionUseCase {
  final ToolRepository _repository;
  const GetPricingSuggestionUseCase(this._repository);

  Future<Map<String, dynamic>> execute({
    required double estimatedValue,
    required double scoreCondicion,
    required String category,
    required String brand,
  }) {
    return _repository.getPricingSuggestion(
      estimatedValue: estimatedValue,
      scoreCondicion: scoreCondicion,
      category: category,
      brand: brand,
    );
  }
}
