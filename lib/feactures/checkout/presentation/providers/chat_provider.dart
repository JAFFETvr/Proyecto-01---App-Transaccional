import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/datasoruce/chat_seen_local_store.dart';
import '../../domain/entitie/message_entity.dart';
import '../../domain/repositories/rental_repository.dart';

class ChatProvider extends ChangeNotifier {
  final RentalRepository _repository;

  List<MessageEntity> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;
  String? _activeRentalId;

  List<MessageEntity> get messages => _messages;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  ChatProvider(this._repository);

  void startChat(String rentalId) {
    if (_activeRentalId == rentalId && _pollTimer != null) return;
    stopChat();
    _activeRentalId = rentalId;
    _loading = true;
    notifyListeners();

    fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => fetchMessages(silent: true));
  }

  void stopChat() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeRentalId = null;
    _messages = [];
    _error = null;
  }

  Future<void> fetchMessages({bool silent = false}) async {
    final rentalId = _activeRentalId;
    if (rentalId == null) return;

    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      final res = await _repository.getMessages(rentalId);
      _messages = res;
      _error = null;
    } catch (e) {
      if (!silent) _error = 'No se pudieron cargar los mensajes.';
    } finally {
      if (!silent) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String text) async {
    final rentalId = _activeRentalId;
    if (rentalId == null || text.trim().isEmpty) return false;

    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final newMsg = await _repository.sendMessage(rentalId, text.trim());
      _messages.add(newMsg);
      return true;
    } catch (e) {
      _error = 'Error al enviar mensaje.';
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  // --- Indicador de mensajes sin leer (punto rojo en el icono de chat) ---
  //
  // No hay push (FCM está deshabilitado), así que el "sin leer" se calcula
  // comparando el último mensaje de la OTRA persona contra una marca de
  // tiempo local ("visto") que se guarda cada vez que se abre/cierra el chat.
  /// Marca el chat de [rentalId] como visto justo ahora. Se llama al abrir y
  /// al cerrar el chat, para que el punto rojo desaparezca.
  Future<void> markChatSeen(String rentalId) async {
    await ChatSeenLocalStore.markSeen(rentalId, DateTime.now());
  }

  /// Devuelve true si hay algún mensaje de la otra persona más reciente que la
  /// última vez que este usuario abrió el chat. No toca el estado del chat
  /// activo (se puede llamar en segundo plano desde la pantalla de
  /// seguimiento sin interferir con el sheet abierto).
  Future<bool> hasUnreadFor(String rentalId, String currentUserId) async {
    try {
      final msgs = await _repository.getMessages(rentalId);
      if (msgs.isEmpty) return false;

      DateTime? lastFromOther;
      for (final m in msgs) {
        if (m.senderId == currentUserId) continue;
        final t = DateTime.tryParse(m.createdAt);
        if (t == null) continue;
        if (lastFromOther == null || t.isAfter(lastFromOther)) {
          lastFromOther = t;
        }
      }
      if (lastFromOther == null) return false;

      final seen = await ChatSeenLocalStore.lastSeen(rentalId);
      if (seen == null) return true;
      return lastFromOther.isAfter(seen);
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    stopChat();
    super.dispose();
  }
}
