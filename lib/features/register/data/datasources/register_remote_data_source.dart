import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';

class RegisterRemoteDataSource {
  final AppHttpClient client;
  RegisterRemoteDataSource(this.client);

  Future<void> start({
    required String nombre,
    required String apellido,
    required String ci,
    required String correo,
    required String celular,
    required String contrasena,
  }) async {
    final url = '${AppConfig.baseUrl}${AppConfig.registerInitEndpoint}';
    final body = {
      'nombre': nombre,
      'apellido': apellido,
      'ci': ci,
      'correo': correo,
      'celular': celular,
      'contrasena': contrasena,
    };
    await client.postJson(url, body); 
  }

  Future<void> verify({
    required String correo,
    required String codigo,
  }) async {
    final url = '${AppConfig.baseUrl}${AppConfig.registerVerifyEndpoint}';
    final body = {
      'correo': correo,
      'codigo': codigo,
    };
    await client.postJson(url, body);
  }
}