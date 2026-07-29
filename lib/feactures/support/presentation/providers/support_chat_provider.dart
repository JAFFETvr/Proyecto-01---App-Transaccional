import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/entitie/support_message_entity.dart';
import '../../domain/repositories/support_repository.dart';

/// Mismo patrón de polling que ChatProvider, pero el hilo se identifica por [ownerId].
class SupportChatProvider extends ChangeNotifier {
  final SupportRepository _repository;

  SupportChatProvider(this._repository);

  List<SupportMessageEntity> _messages = [];
  bool _loading = false;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;
  String? _activeOwnerId;
  bool _asAdmin = false;

  List<SupportMessageEntity> get messages => _messages;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  void startChat(String ownerId, {required bool asAdmin}) {
    if (_activeOwnerId == ownerId && _pollTimer != null) return;
    stopChat();
    _activeOwnerId = ownerId;
    _asAdmin = asAdmin;
    _loading = true;
    notifyListeners();

    fetchMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => fetchMessages(silent: true));
  }

  void stopChat() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeOwnerId = null;
    _messages = [];
    _error = null;
  }

  Future<void> fetchMessages({bool silent = false}) async {
    final ownerId = _activeOwnerId;
    if (ownerId == null) return;

    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      _messages = _asAdmin
          ? await _repository.getThreadMessages(ownerId)
          : await _repository.getMyMessages();
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
    final ownerId = _activeOwnerId;
    if (ownerId == null || text.trim().isEmpty) return false;

    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final newMsg = _asAdmin
          ? await _repository.sendThreadMessage(ownerId, text.trim())
          : await _repository.sendMyMessage(text.trim());
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

  @override
  void dispose() {
    stopChat();
    super.dispose();
  }
}
