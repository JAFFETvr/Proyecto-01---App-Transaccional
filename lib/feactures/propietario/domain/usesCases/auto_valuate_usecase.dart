import '../repositories/tool_repository.dart';

class AutoValuateUseCase {
  final ToolRepository _repository;
  const AutoValuateUseCase(this._repository);

  Future<Map<String, dynamic>> execute({
    required String name,
    required double scoreCondicion,
    required String category,
    required String brand,
    int? ageMonths,
    double? precioBaseManual,
    bool ticketValidado = false,
  }) {
    return _repository.autoValuate(
      name: name,
      scoreCondicion: scoreCondicion,
      category: category,
      brand: brand,
      ageMonths: ageMonths,
      precioBaseManual: precioBaseManual,
      ticketValidado: ticketValidado,
    );
  }
}
