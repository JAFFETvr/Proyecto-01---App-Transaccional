import '../data/datasoruce/rental_remote_datasource.dart';
import '../data/repositories/rental_repository_impl.dart';
import '../domain/usesCases/create_rental_usecase.dart';
import '../domain/usesCases/get_rentals_usecase.dart';
import '../domain/usesCases/get_rental_usecase.dart';
import '../domain/usesCases/confirm_delivery_usecase.dart';
import '../domain/usesCases/confirm_return_usecase.dart';
import '../domain/usesCases/dispute_rental_usecase.dart';
import '../domain/usesCases/cancel_rental_usecase.dart';
import '../domain/usesCases/verify_contract_usecase.dart';
import '../domain/usesCases/get_preference_usecase.dart';
import '../domain/usesCases/confirm_payment_usecase.dart';
import '../domain/usesCases/reconcile_payment_usecase.dart';
import '../domain/usesCases/stream_rental_usecase.dart';
import '../domain/repositories/rental_repository.dart';

class CheckoutDI {
  static final _datasource = RentalRemoteDatasource();
  static final _repository = RentalRepositoryImpl(_datasource);

  static CreateRentalUseCase provideCreateRental() => CreateRentalUseCase(_repository);
  static GetRentalsUseCase provideGetRentals() => GetRentalsUseCase(_repository);
  static GetRentalUseCase provideGetRental() => GetRentalUseCase(_repository);
  static ConfirmDeliveryUseCase provideConfirmDelivery() => ConfirmDeliveryUseCase(_repository);
  static ConfirmReturnUseCase provideConfirmReturn() => ConfirmReturnUseCase(_repository);
  static DisputeRentalUseCase provideDisputeRental() => DisputeRentalUseCase(_repository);
  static CancelRentalUseCase provideCancelRental() => CancelRentalUseCase(_repository);
  static VerifyContractUseCase provideVerifyContract() => VerifyContractUseCase(_repository);
  static GetPreferenceUseCase provideGetPreference() => GetPreferenceUseCase(_repository);
  static ConfirmPaymentUseCase provideConfirmPayment() => ConfirmPaymentUseCase(_repository);
  static ReconcilePaymentUseCase provideReconcilePayment() => ReconcilePaymentUseCase(_repository);
  static StreamRentalUseCase provideStreamRental() => StreamRentalUseCase(_repository);
  static RentalRepository get repository => _repository;
}
