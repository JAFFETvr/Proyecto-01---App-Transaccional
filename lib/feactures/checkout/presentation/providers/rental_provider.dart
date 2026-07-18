import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../../core/error/app_error.dart';
import '../../domain/entitie/rental_entity.dart';
import '../../domain/usesCases/create_rental_usecase.dart';
import '../../domain/usesCases/get_rentals_usecase.dart';
import '../../domain/usesCases/get_rental_usecase.dart';
import '../../domain/usesCases/confirm_delivery_usecase.dart';
import '../../domain/usesCases/confirm_return_usecase.dart';
import '../../domain/usesCases/dispute_rental_usecase.dart';
import '../../domain/usesCases/cancel_rental_usecase.dart';
import '../../domain/usesCases/verify_contract_usecase.dart';
import '../../domain/usesCases/get_preference_usecase.dart';
import '../../domain/usesCases/stream_rental_usecase.dart';

class RentalProvider extends ChangeNotifier {
  final CreateRentalUseCase _createRental;
  final GetRentalsUseCase _getRentals;
  final GetRentalUseCase _getRental;
  final ConfirmDeliveryUseCase _confirmDelivery;
  final ConfirmReturnUseCase _confirmReturn;
  final DisputeRentalUseCase _disputeRental;
  final CancelRentalUseCase _cancelRental;
  final VerifyContractUseCase _verifyContract;
  final GetPreferenceUseCase _getPreference;
  final StreamRentalUseCase _streamRental;

  StreamSubscription<RentalEntity>? _rentalSubscription;

  List<RentalEntity> _rentals = [];
  RentalEntity? _currentRental;
  bool _loading = false;
  String? _error;

  List<RentalEntity> get rentals => List.unmodifiable(_rentals);
  RentalEntity? get currentRental => _currentRental;
  bool get loading => _loading;
  String? get error => _error;

  RentalProvider({
    required CreateRentalUseCase createRental,
    required GetRentalsUseCase getRentals,
    required GetRentalUseCase getRental,
    required ConfirmDeliveryUseCase confirmDelivery,
    required ConfirmReturnUseCase confirmReturn,
    required DisputeRentalUseCase disputeRental,
    required CancelRentalUseCase cancelRental,
    required VerifyContractUseCase verifyContract,
    required GetPreferenceUseCase getPreference,
    required StreamRentalUseCase streamRental,
  })  : _createRental = createRental,
        _getRentals = getRentals,
        _getRental = getRental,
        _confirmDelivery = confirmDelivery,
        _confirmReturn = confirmReturn,
        _disputeRental = disputeRental,
        _cancelRental = cancelRental,
        _verifyContract = verifyContract,
        _getPreference = getPreference,
        _streamRental = streamRental;

  void listenToRental(String id) {
    _rentalSubscription?.cancel();
    _rentalSubscription = _streamRental.execute(id).listen(
      (updatedRental) {
        _currentRental = updatedRental;
        final idx = _rentals.indexWhere((r) => r.id == id);
        if (idx != -1) {
          _rentals[idx] = updatedRental;
        } else {
          _rentals.add(updatedRental);
        }
        notifyListeners();
      },
      onError: (err) {
        if (err is AppError) {
          _error = err.userMessage;
        } else {
          _error = 'Error de conexión con el servidor.';
        }
        notifyListeners();
      },
    );
  }

  void stopListeningRental() {
    _rentalSubscription?.cancel();
    _rentalSubscription = null;
  }

  @override
  void dispose() {
    _rentalSubscription?.cancel();
    super.dispose();
  }

  void clearState() {
    _rentals = [];
    _currentRental = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void setCurrentRental(RentalEntity? rental) {
    _currentRental = rental;
    notifyListeners();
  }

  Future<bool> createRental({
    required String toolId,
    required String startDate,
    required String endDate,
    String paymentMethod = 'card',
    String? cardToken,
    String? payerEmail,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final rental = await _createRental.execute(
        toolId: toolId,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
        payerEmail: payerEmail,
      );
      _rentals.add(rental);
      _currentRental = rental;
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

  Future<void> fetchRentals() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _rentals = await _getRentals.execute();
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRental(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRental = await _getRental.execute(id);
      final idx = _rentals.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _rentals[idx] = _currentRental!;
      }
    } on AppError catch (e) {
      _error = e.userMessage;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmDelivery(
    String id, {
    double? latitude,
    double? longitude,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _confirmDelivery.execute(
        id,
        latitude: latitude,
        longitude: longitude,
      );
      _currentRental = updated;
      final idx = _rentals.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _rentals[idx] = updated;
      }
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

  Future<bool> confirmReturn(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _confirmReturn.execute(id);
      _currentRental = updated;
      final idx = _rentals.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _rentals[idx] = updated;
      }
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

  Future<bool> disputeRental(String id, String reason) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _disputeRental.execute(id, reason);
      _currentRental = updated;
      final idx = _rentals.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _rentals[idx] = updated;
      }
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

  Future<String?> fetchPreference(String rentalId, String payerEmail) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _getPreference.execute(rentalId, payerEmail);
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al servidor.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRental(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _cancelRental.execute(id);
      _rentals.removeWhere((r) => r.id == id);
      if (_currentRental?.id == id) {
        _currentRental = null;
      }
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

  Future<Map<String, dynamic>?> verifyContract(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _verifyContract.execute(id);
    } on AppError catch (e) {
      _error = e.userMessage;
      return null;
    } catch (_) {
      _error = 'Sin conexión al verificar contrato.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
