import '../repositories/register_repository.dart';

class VerifyKycUseCase {
  final RegisterRepository _repository;
  const VerifyKycUseCase(this._repository);

  Future<Map<String, dynamic>> execute({
    required String inePath,
    required String selfiePath,
  }) {
    return _repository.verifyKyc(
      inePath: inePath,
      selfiePath: selfiePath,
    );
  }
}
