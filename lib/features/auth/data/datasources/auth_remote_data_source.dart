import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:stopfire_mobile/core/auth/last_login_recorder.dart'; // NUEVO

class AuthRemoteDataSource {
  final AppHttpClient client;
  AuthRemoteDataSource(this.client);

  Future<String> login({
    required String correo,
    required String contrasena,
  }) async {
    final url = '${AppConfig.baseUrl}${AppConfig.loginEndpoint}';
    if (AppConfig.httpVerboseLogging) {
      debugPrint('AuthRemoteDataSource.login -> $url');
      debugPrint('AuthRemoteDataSource.login -> payload: {correo: $correo, contrasena: ${AppConfig.httpLogSensitive ? contrasena : "***"}}');
    }

    final body = {'correo': correo, 'contrasena': contrasena};

    try {
      final data = await client.postJson(url, body);

      // NUEVO: guardar UltimoIngreso desde la respuesta del login (no altera el flujo)
      if (data is Map<String, dynamic>) {
        await LastLoginRecorder.recordFromLoginResponse(data);
      }

      if (AppConfig.httpVerboseLogging) {
        debugPrint('AuthRemoteDataSource.login <- parsed: $data');
      }

      final token = (data['token'] ??
              data['accessToken'] ??
              data['access_token'] ??
              data['jwt'] ??
              data['raw'])
          ?.toString();

      if (AppConfig.httpVerboseLogging) {
        final preview = token == null ? 'null' : '${token.substring(0, min(12, token.length))}...';
        debugPrint('AuthRemoteDataSource.login <- token: $preview');
      }

      if (token == null || token.isEmpty) {
        throw HttpFailure('Respuesta sin token válido');
      }

      return token;
    } on HttpFailure catch (e) {
      if (e.toString().contains('HTTP 401')) {
        throw HttpFailure('Correo o contraseña incorrectos');
      }
      rethrow;
    }
  }

  // NUEVO: ping para registrar último ingreso con token existente
  Future<void> pingUltimoIngreso(String token) async {
    final url = '${AppConfig.baseUrl}/api/Usuarios/ultimo-ingreso';
    try {
      await client.postJson(
        url,
        {}, // cuerpo vacío
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
    } catch (_) {
      // no romper flujo si falla
    }
  }
}