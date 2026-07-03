import '../../domain/entitie/tool_entity.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasoruce/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDatasource _datasource;
  const CatalogRepositoryImpl(this._datasource);

  @override
  Future<List<ToolEntity>> getTools({bool onlyAvailable = false, String search = ''}) =>
      _datasource.getTools(onlyAvailable: onlyAvailable, search: search);
}