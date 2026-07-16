import '../../domain/entitie/user_entity.dart';
import '../../domain/repositories/login_repository.dart';
import '../datasoruce/login_remote_datasource.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDatasource _datasource;

  const LoginRepositoryImpl(this._datasource);

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) {
    return _datasource.login(email: email, password: password);
  }
}