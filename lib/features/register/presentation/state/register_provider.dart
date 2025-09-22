import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:stopfire_mobile/features/register/domain/usecases/start_registration_usecase.dart';
import 'package:stopfire_mobile/features/register/domain/usecases/verify_registration_usecase.dart';

class RegisterProvider extends ChangeNotifier {
  final StartRegistrationUseCase startUseCase;
  final VerifyRegistrationUseCase verifyUseCase;

  bool loading = false;
  String? error;

  RegisterProvider({
    required this.startUseCase,
    required this.verifyUseCase,
  });

  Future<bool> start({
    required String nombre,
    required String apellido,
    required String ci,
    required String correo,
    required String celular,
    required String contrasena,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await startUseCase(
        nombre: nombre,
        apellido: apellido,
        ci: ci,
        correo: correo,
        celular: celular,
        contrasena: contrasena,
      );
      return true;
    } on HttpFailure catch (e) {
      if (e.message.contains('HTTP 409')) {
        error = 'Ya existe una cuenta con ese correo o CI';
      } else if (e.message.contains('HTTP 400')) {
        error = 'Datos inválidos. Revisa la información ingresada';
      } else {
        error = e.message;
      }
      return false;
    } catch (_) {
      error = 'Error inesperado';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> verify({required String correo, required String codigo}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await verifyUseCase(correo: correo, codigo: codigo);
      return true;
    } on HttpFailure catch (e) {
      if (e.message.contains('HTTP 400')) {
        error = 'Código inválido o expirado';
      } else {
        error = e.message;
      }
      return false;
    } catch (_) {
      error = 'Error inesperado';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}