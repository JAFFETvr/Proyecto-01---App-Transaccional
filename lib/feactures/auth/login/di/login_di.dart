import '../data/datasoruce/login_remote_datasource.dart';
import '../data/repositories/login_repository_impl.dart';
import '../domain/usesCases/login_usecase.dart';

class LoginDI {
  static LoginUseCase provideLoginUseCase() {
    final datasource = LoginRemoteDatasource();
    final repository = LoginRepositoryImpl(datasource);
    return LoginUseCase(repository);
  }
}