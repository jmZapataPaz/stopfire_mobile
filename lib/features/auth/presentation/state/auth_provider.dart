import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:stopfire_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';

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
      ensureRoleParsed();
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

  int? _roleId;
  int? get roleId => _roleId;
  bool get isBombero => _roleId == 2;
  bool get isCiudadano => _roleId == 3;

  get estacionId => null;

  void setRoleId(int? v) {
    if (_roleId == v) return;
    _roleId = v;
    notifyListeners();
  }
  void ensureRoleParsed() {
    if (_roleId != null) return;
    final t = token;
    if (t == null || t.isEmpty) return;
    final rid = _extractRoleIdFromToken(t);
    if (rid != null) {
      _roleId = rid;
      notifyListeners();
    }
  }

  int? _extractRoleIdFromToken(String jwt) {
    try {
      final claims = JwtDecoder.decode(jwt);
      final v = claims['rol_id'] ??
          claims['role_id'] ??
          claims['rolId'] ??
          claims['roleId'] ??
          claims['RolId'] ??
          claims['RoleId'] ??
          claims['rol'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
    } catch (_) {}
    return null;
  }
}