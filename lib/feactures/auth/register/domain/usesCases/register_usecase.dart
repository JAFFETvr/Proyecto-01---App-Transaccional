import '../entitie/user_entity.dart';
import '../repositories/register_repository.dart';

class RegisterUseCase {
  final RegisterRepository _repository;
  const RegisterUseCase(this._repository);

  Future<UserEntity> execute({
    required String name,
    required String email,
    required String password,
    required String role,
  }) {
    return _repository.register(
        name: name, email: email, password: password, role: role);
  }
}