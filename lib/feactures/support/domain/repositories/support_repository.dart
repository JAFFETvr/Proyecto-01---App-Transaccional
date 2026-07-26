import '../entitie/support_message_entity.dart';
import '../entitie/support_thread_entity.dart';

abstract class SupportRepository {
  /// Mensajes del hilo de soporte del propietario autenticado.
  Future<List<SupportMessageEntity>> getMyMessages();

  /// Envía un mensaje en el hilo de soporte propio (uso del propietario).
  Future<SupportMessageEntity> sendMyMessage(String message);

  /// Lista los hilos de soporte con actividad (uso del administrador).
  Future<List<SupportThreadEntity>> getThreads();

  /// Mensajes del hilo de soporte de un propietario específico (uso del administrador).
  Future<List<SupportMessageEntity>> getThreadMessages(String ownerId);

  /// Responde en el hilo de soporte de un propietario (uso del administrador).
  Future<SupportMessageEntity> sendThreadMessage(String ownerId, String message);
}
