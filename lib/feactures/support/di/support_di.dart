import '../data/datasoruce/support_remote_datasource.dart';
import '../data/repositories/support_repository_impl.dart';
import '../domain/repositories/support_repository.dart';
import '../presentation/providers/support_chat_provider.dart';
import '../presentation/providers/support_threads_provider.dart';

class SupportDI {
  static final _datasource = SupportRemoteDatasource();
  static final SupportRepository repository = SupportRepositoryImpl(_datasource);

  static SupportChatProvider provideSupportChatProvider() =>
      SupportChatProvider(repository);

  static SupportThreadsProvider provideSupportThreadsProvider() =>
      SupportThreadsProvider(repository);
}
