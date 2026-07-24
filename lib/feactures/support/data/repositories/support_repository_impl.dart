import '../../domain/entitie/support_message_entity.dart';
import '../../domain/entitie/support_thread_entity.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasoruce/support_remote_datasource.dart';

class SupportRepositoryImpl implements SupportRepository {
  final SupportRemoteDatasource _datasource;

  SupportRepositoryImpl(this._datasource);

  @override
  Future<List<SupportMessageEntity>> getMyMessages() =>
      _datasource.getMyMessages();

  @override
  Future<SupportMessageEntity> sendMyMessage(String message) =>
      _datasource.sendMyMessage(message);

  @override
  Future<List<SupportThreadEntity>> getThreads() => _datasource.getThreads();

  @override
  Future<List<SupportMessageEntity>> getThreadMessages(String ownerId) =>
      _datasource.getThreadMessages(ownerId);

  @override
  Future<SupportMessageEntity> sendThreadMessage(String ownerId, String message) =>
      _datasource.sendThreadMessage(ownerId, message);
}
