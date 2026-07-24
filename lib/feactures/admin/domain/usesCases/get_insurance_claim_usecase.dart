import '../entitie/insurance_claim_entity.dart';
import '../repositories/admin_repository.dart';

class GetInsuranceClaimUseCase {
  final AdminRepository _repository;
  const GetInsuranceClaimUseCase(this._repository);

  Future<InsuranceClaimEntity> execute(String rentalId) =>
      _repository.getInsuranceClaim(rentalId);
}
