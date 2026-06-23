import '../../domain/entitie/user_entity.dart';
import '../../domain/repositories/register_repository.dart';
import '../datasoruce/register_remote_datasource.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDatasource _datasource;
  const RegisterRepositoryImpl(this._datasource);

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    required String ine,
  }) {
    return _datasource.register(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
      ine: ine,
    );
  }
}