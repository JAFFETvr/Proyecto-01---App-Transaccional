import '../entitie/user_entity.dart';
import '../repositories/login_repository.dart';

// Caso de uso: orquesta la lógica de login.
// Aquí iría validación de negocio extra si la hubiera.
class LoginUseCase {
  final LoginRepository _repository;

  const LoginUseCase(this._repository);

  Future<UserEntity> execute({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}