import 'package:stopfire_mobile/features/register/domain/repositories/register_repository.dart';

class StartRegistrationUseCase {
  final RegisterRepository repository;
  StartRegistrationUseCase(this.repository);

  Future<void> call({
    required String nombre,
    required String apellido,
    required String ci,
    required String correo,
    required String celular,
    required String contrasena,
  }) {
    return repository.start(
      nombre: nombre,
      apellido: apellido,
      ci: ci,
      correo: correo,
      celular: celular,
      contrasena: contrasena,
    );
  }
}