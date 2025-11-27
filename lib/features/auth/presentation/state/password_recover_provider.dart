import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/features/auth/domain/usecases/start_password_recover_usecase.dart';
import 'package:stopfire_mobile/features/auth/domain/usecases/verify_password_recover_usecase.dart';

class PasswordRecoverProvider extends ChangeNotifier {
  final StartPasswordRecoverUseCase startUseCase;
  final VerifyPasswordRecoverUseCase verifyUseCase;

  bool loading = false;
  String? error;
  String? correoEnProceso;

  PasswordRecoverProvider({
    required this.startUseCase,
    required this.verifyUseCase,
  });

  Future<void> iniciar(String correo) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await startUseCase.call(correo);
      correoEnProceso = correo;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verificar(String codigo, String nuevaContrasena) async {
    if (correoEnProceso == null) return false;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await verifyUseCase.call(correoEnProceso!, codigo, nuevaContrasena);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}