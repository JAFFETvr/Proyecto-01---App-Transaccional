import '../repositories/admin_repository.dart';
import '../../../checkout/domain/entitie/rental_entity.dart';

class GetAdminRentalsUseCase {
  final AdminRepository _repository;
  const GetAdminRentalsUseCase(this._repository);

  Future<List<RentalEntity>> execute({String? statusFilter}) =>
      _repository.getRentals(statusFilter: statusFilter);
}
