import '../data/datasoruce/register_remote_datasource.dart';
import '../data/repositories/register_repository_impl.dart';
import '../domain/usesCases/register_usecase.dart';
import '../domain/usesCases/verify_kyc_usecase.dart';

class RegisterDI {
  static final _datasource = RegisterRemoteDatasource();
  static final _repository = RegisterRepositoryImpl(_datasource);

  static RegisterUseCase provideRegisterUseCase() => RegisterUseCase(_repository);
  static VerifyKycUseCase provideVerifyKycUseCase() => VerifyKycUseCase(_repository);
}