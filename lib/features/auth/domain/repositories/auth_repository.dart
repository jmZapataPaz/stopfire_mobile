abstract class AuthRepository {
  Future<String> login({required String correo, required String contrasena});
  Future<String?> getSavedToken();
  Future<void> logout();
}