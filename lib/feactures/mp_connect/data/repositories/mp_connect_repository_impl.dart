import '../../domain/repositories/mp_connect_repository.dart';
import '../datasoruce/mp_connect_remote_datasource.dart';

class MpConnectRepositoryImpl implements MpConnectRepository {
  final MpConnectRemoteDatasource _datasource;

  MpConnectRepositoryImpl(this._datasource);

  @override
  Future<bool> getStatus() => _datasource.getStatus();

  @override
  Future<String> getAuthURL() => _datasource.getAuthURL();
}
