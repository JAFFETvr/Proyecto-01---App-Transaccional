import 'package:flutter/material.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/entitie/bank_account_entity.dart';
import '../../domain/repositories/bank_account_repository.dart';

class BankAccountProvider extends ChangeNotifier {
  final BankAccountRepository _repository;

  BankAccountProvider({required BankAccountRepository repository})
    : _repository = repository;

  BankAccountEntity? _account;
  bool _loading = false;
  String? _error;

  BankAccountEntity? get account => _account;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _repository.getBankAccount();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String clabe,
    required String accountHolder,
    required String bankName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _repository.saveBankAccount(
        clabe: clabe,
        accountHolder: accountHolder,
        bankName: bankName,
      );
      return true;
    } on AppError catch (e) {
      _error = e.userMessage;
      return false;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
