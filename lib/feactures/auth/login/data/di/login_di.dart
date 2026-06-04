import '../datasoruce/login_remote_datasource.dart';
import '../repositories/login_repository_impl.dart';
import '../../domain/usesCases/login_usecase.dart';

// Inyección de dependencias manual (sin librería externa).
// Crea y conecta todas las capas del feature Login.
class LoginDI {
  static LoginUseCase provideLoginUseCase() {
    final datasource = LoginRemoteDatasource();
    final repository = LoginRepositoryImpl(datasource);
    return LoginUseCase(repository);
  }
}