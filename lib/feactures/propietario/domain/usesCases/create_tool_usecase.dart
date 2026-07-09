import '../entitie/tool_entity.dart';
import '../repositories/tool_repository.dart';

class CreateToolUseCase {
  final ToolRepository _repository;
  const CreateToolUseCase(this._repository);

  Future<ToolEntity> execute({
    required String name,
    required String description,
    required String category,
    required bool isAvailable,
    required double estimatedValue,
    required double dailyRate,
    double? latitude,
    double? longitude,
    String brand = 'Generico',
    int ageMonths = 12,
    double conditionScore = 0.70,
  }) {
    return _repository.createTool(
      name: name,
      description: description,
      category: category,
      isAvailable: isAvailable,
      estimatedValue: estimatedValue,
      dailyRate: dailyRate,
      latitude: latitude,
      longitude: longitude,
      brand: brand,
      ageMonths: ageMonths,
      conditionScore: conditionScore,
    );
  }
}