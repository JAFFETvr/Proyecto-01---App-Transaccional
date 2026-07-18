import 'package:flutter/material.dart';
import '../../../../core/error/app_error.dart';
import '../../data/datasoruce/card_remote_datasource.dart';
import '../../domain/entitie/saved_card_entity.dart';
import '../../domain/repositories/card_repository.dart';

class CardProvider extends ChangeNotifier {
  final CardRepository _repository;
  final CardRemoteDatasource _tokenizer;

  CardProvider({required CardRepository repository, required CardRemoteDatasource tokenizer})
      : _repository = repository,
        _tokenizer = tokenizer;

  List<SavedCardEntity> _cards = [];
  bool _loading = false;
  String? _error;

  List<SavedCardEntity> get cards => List.unmodifiable(_cards);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchCards() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cards = await _repository.getCards();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Tokeniza la tarjeta directo contra Mercado Pago y guarda el resultado.
  /// Los datos completos de la tarjeta nunca llegan a nuestro backend.
  Future<bool> addCard({
    required String cardNumber,
    required String cardholderName,
    required int expirationMonth,
    required int expirationYear,
    required String securityCode,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final publicKey = await _repository.getMpPublicKey();
      if (publicKey.isEmpty) {
        _error = 'La pasarela de pagos no está configurada. Intenta más tarde.';
        return false;
      }
      final token = await _tokenizer.tokenizeCard(
        publicKey: publicKey,
        cardNumber: cardNumber,
        cardholderName: cardholderName,
        expirationMonth: expirationMonth,
        expirationYear: expirationYear,
        securityCode: securityCode,
      );
      final card = await _repository.addCard(token);
      _cards = [card, ..._cards];
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'No se pudo guardar la tarjeta.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      await _repository.deleteCard(cardId);
      _cards = _cards.where((c) => c.id != cardId).toList();
      notifyListeners();
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'No se pudo eliminar la tarjeta.';
      return false;
    }
  }
}
