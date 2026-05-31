import '../entitie/user_entity.dart';

// Contrato abstracto — el dominio sólo conoce esta interfaz,
// nunca la implementación HTTP real.
abstract class LoginRepository {
  Future<UserEntity> login({
    required String email,
    required String password,
  });
}