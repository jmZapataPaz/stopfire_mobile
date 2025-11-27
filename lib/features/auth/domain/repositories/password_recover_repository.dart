abstract class PasswordRecoverRepository {
  Future<void> iniciar(String correo);
  Future<void> verificar(String correo, String codigo, String nuevaContrasena);
}