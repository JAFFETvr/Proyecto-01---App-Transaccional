import '../data/datasoruce/admin_remote_datasource.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/usesCases/get_admin_stats_usecase.dart';
import '../domain/usesCases/get_admin_rentals_usecase.dart';
import '../domain/usesCases/resolve_dispute_usecase.dart';

class AdminDI {
  static final _datasource = AdminRemoteDatasource();
  static final _repository = AdminRepositoryImpl(_datasource);

  static GetAdminStatsUseCase provideGetAdminStats() =>
      GetAdminStatsUseCase(_repository);
  static GetAdminRentalsUseCase provideGetAdminRentals() =>
      GetAdminRentalsUseCase(_repository);
  static ResolveDisputeUseCase provideResolveDispute() =>
      ResolveDisputeUseCase(_repository);
}
