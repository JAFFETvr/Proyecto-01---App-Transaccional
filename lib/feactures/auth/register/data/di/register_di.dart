import '../datasoruce/register_remote_datasource.dart';
import '../repositories/register_repository_impl.dart';
import '../../domain/usesCases/register_usecase.dart';

class RegisterDI {
  static RegisterUseCase provideRegisterUseCase() {
    final datasource = RegisterRemoteDatasource();
    final repository = RegisterRepositoryImpl(datasource);
    return RegisterUseCase(repository);
  }
}