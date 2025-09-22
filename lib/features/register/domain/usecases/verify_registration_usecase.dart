import 'package:stopfire_mobile/features/register/domain/repositories/register_repository.dart';

class VerifyRegistrationUseCase {
  final RegisterRepository repository;
  VerifyRegistrationUseCase(this.repository);

  Future<void> call({
    required String correo,
    required String codigo,
  }) {
    return repository.verify(correo: correo, codigo: codigo);
  }
}