import 'package:stopfire_mobile/features/auth/domain/repositories/password_recover_repository.dart';

class StartPasswordRecoverUseCase {
  final PasswordRecoverRepository repository;
  StartPasswordRecoverUseCase(this.repository);

  Future<void> call(String correo) => repository.iniciar(correo);
}