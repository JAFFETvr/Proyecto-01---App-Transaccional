import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/config/api_config.dart';
import '../../domain/entitie/bank_account_entity.dart';

class BankAccountRemoteDatasource {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = json.decode(utf8.decode(res.bodyBytes));
    final msg = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Error del servidor';
    throw AppError(statusCode: res.statusCode, message: msg);
  }

  BankAccountEntity _fromJson(Map<String, dynamic> j) => BankAccountEntity(
    clabe: j['clabe'] as String? ?? '',
    accountHolder: j['account_holder'] as String? ?? '',
    bankName: j['bank_name'] as String? ?? '',
    registered: j['registered'] as bool? ?? false,
  );

  Future<BankAccountEntity> getBankAccount() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/bank-account'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<BankAccountEntity> saveBankAccount({
    required String clabe,
    required String accountHolder,
    required String bankName,
  }) async {
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/auth/bank-account'),
        headers: await _authHeaders,
        body: json.encode({
          'clabe': clabe,
          'account_holder': accountHolder,
          'bank_name': bankName,
        }),
      );
      _throwIfError(res);
      return _fromJson(json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }

  Future<void> deleteBankAccount() async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/auth/bank-account'),
        headers: await _authHeaders,
      );
      _throwIfError(res);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError(statusCode: 0, message: 'Sin conexión.');
    }
  }
}
