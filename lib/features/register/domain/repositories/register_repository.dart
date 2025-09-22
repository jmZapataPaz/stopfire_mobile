abstract class RegisterRepository {
  Future<void> start({
    required String nombre,
    required String apellido,
    required String ci,
    required String correo,
    required String celular,
    required String contrasena,
  });

  Future<void> verify({
    required String correo,
    required String codigo,
  });
}