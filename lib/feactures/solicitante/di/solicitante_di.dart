import '../data/datasoruce/catalog_remote_datasource.dart';
import '../data/repositories/catalog_repository_impl.dart';
import '../domain/usesCases/get_catalog_usecase.dart';

class SolicitanteDI {
  static GetCatalogUseCase provideGetCatalog() {
    final datasource = CatalogRemoteDatasource();
    final repository = CatalogRepositoryImpl(datasource);
    return GetCatalogUseCase(repository);
  }
}