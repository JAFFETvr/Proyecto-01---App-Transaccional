import '../data/datasoruce/mp_connect_remote_datasource.dart';
import '../data/repositories/mp_connect_repository_impl.dart';
import '../domain/repositories/mp_connect_repository.dart';
import '../presentation/providers/mp_connect_provider.dart';

class MpConnectDI {
  static final _datasource = MpConnectRemoteDatasource();
  static final MpConnectRepository _repository = MpConnectRepositoryImpl(_datasource);

  static MpConnectProvider provideMpConnectProvider() =>
      MpConnectProvider(repository: _repository);
}
