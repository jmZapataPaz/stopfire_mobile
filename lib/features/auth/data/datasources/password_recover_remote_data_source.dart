import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';

class PasswordRecoverRemoteDataSource {
  final AppHttpClient client;
  PasswordRecoverRemoteDataSource(this.client);

  Future<void> iniciar({required String correo}) async {
    final url = '${AppConfig.baseUrl}${AppConfig.passwordRecoverInitEndpoint}';
    final body = {'Correo': correo};
    final res = await client.postJson(url, body);
    if (res is Map && res['mensaje'] != null) {
      // opcional log
    }
  }

  Future<void> verificar({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    final url = '${AppConfig.baseUrl}${AppConfig.passwordRecoverVerifyEndpoint}';
    final body = {
      'Correo': correo,
      'Codigo': codigo,
      'NuevaContrasena': nuevaContrasena,
    };
    final res = await client.postJson(url, body);
    if (res is Map && res['mensaje'] != null) {
      // opcional log
    }
  }
}