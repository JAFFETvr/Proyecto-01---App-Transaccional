import '../entitie/user_entity.dart';

abstract class RegisterRepository {
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });
}