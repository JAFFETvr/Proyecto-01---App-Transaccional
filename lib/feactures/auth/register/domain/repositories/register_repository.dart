import '../entitie/user_entity.dart';

abstract class RegisterRepository {
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String ine,
  });

  Future<Map<String, dynamic>> verifyKyc({
    required String inePath,
    required String selfiePath,
  });
}