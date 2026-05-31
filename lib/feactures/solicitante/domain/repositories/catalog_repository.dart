import '../entitie/tool_entity.dart';

abstract class CatalogRepository {
  Future<List<ToolEntity>> getTools({bool onlyAvailable = false});
}