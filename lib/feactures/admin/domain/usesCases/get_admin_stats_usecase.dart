import '../entitie/admin_stats_entity.dart';
import '../repositories/admin_repository.dart';

class GetAdminStatsUseCase {
  final AdminRepository _repository;
  const GetAdminStatsUseCase(this._repository);

  Future<AdminStatsEntity> execute() => _repository.getStats();
}
