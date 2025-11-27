import 'package:stopfire_mobile/features/auth/domain/repositories/password_recover_repository.dart';

class VerifyPasswordRecoverUseCase {
  final PasswordRecoverRepository repository;
  VerifyPasswordRecoverUseCase(this.repository);

  Future<void> call(String correo, String codigo, String nuevaContrasena) =>
      repository.verificar(correo, codigo, nuevaContrasena);
}