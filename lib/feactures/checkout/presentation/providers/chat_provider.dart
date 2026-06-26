import 'dart:async';
import 'package:flutter/foundation.dart';

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

  @override
  void dispose() {
    stopChat();
    super.dispose();
  }
}
