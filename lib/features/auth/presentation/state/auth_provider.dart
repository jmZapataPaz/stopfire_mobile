import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:stopfire_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';

class AuthProvider extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final AuthRepository repository;

  bool isLoading = false;
  String? error;
  String? token;

  AuthProvider({
    required this.loginUseCase,
    required this.repository,
  });

  Future<void> loadInitialSession() async {
    token = await repository.getSavedToken();
    debugPrint('AuthProvider.loadInitialSession -> token? ${token != null}');
  }

  Future<bool> login(String correo, String contrasena) async {
    if (contrasena.length < 8) {
      error = 'La contraseña tiene que ser mínimo de 8 caracteres';
      isLoading = false;
      notifyListeners();
      return false;
    }

    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint('AuthProvider.login -> correo: $correo, passLen: ${contrasena.length}');
    try {
      final t = await loginUseCase(correo, contrasena);
      token = t;
      debugPrint('AuthProvider.login <- success, token saved: ${t.isNotEmpty}');
      return true;
    } on HttpFailure catch (e, st) {
      if (e.message.contains('HTTP 401')) {
        error = 'Correo o contraseña incorrectos';
      } else {
        error = e.message;
      }
      debugPrint('AuthProvider.login !! http error: ${e.message}');
      debugPrint('$st');
      return false;
    } catch (e, st) {
      error = 'Error inesperado';
      debugPrint('AuthProvider.login !! error: $e');
      debugPrint('$st');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repository.logout();
    token = null;
    notifyListeners();
  }
}