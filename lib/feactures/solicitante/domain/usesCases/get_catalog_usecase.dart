import '../entitie/tool_entity.dart';
import '../repositories/catalog_repository.dart';

class GetCatalogUseCase {
  final CatalogRepository _repository;
  const GetCatalogUseCase(this._repository);

  Future<List<ToolEntity>> execute({bool onlyAvailable = false}) =>
      _repository.getTools(onlyAvailable: onlyAvailable);
}