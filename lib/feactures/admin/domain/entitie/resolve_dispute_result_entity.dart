import '../../../checkout/domain/entitie/rental_entity.dart';
import 'insurance_claim_entity.dart';

class ResolveDisputeResultEntity {
  final RentalEntity rental;
  // null si la herramienta no tenía seguro activo o si la disputa no se
  // resolvió a favor del propietario.
  final InsuranceClaimEntity? insuranceClaim;

  const ResolveDisputeResultEntity({
    required this.rental,
    this.insuranceClaim,
  });
}
