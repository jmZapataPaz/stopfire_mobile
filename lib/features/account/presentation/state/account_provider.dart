import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';
import 'package:stopfire_mobile/features/account/domain/entities/account.dart';
import 'package:stopfire_mobile/features/account/domain/usecases/get_account_usecase.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:stopfire_mobile/core/config/app_config.dart';

class AccountProvider extends ChangeNotifier {
  final GetAccountUseCase getAccountUseCase;

  AccountProvider({required this.getAccountUseCase});

  Account? _account;
  bool _loading = false;
  String? _error;

  Account? get account => _account;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFromToken(String token) async {
    final id = JwtDecoder.getUserIdFromSub(token);
    if (id == null) {
      _error = 'Token inválido';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _account = await getAccountUseCase(id);
    } catch (e) {
      _error = e.toString();
      _account = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _account = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // UNICO método para actualizar cuenta (hace logs según AppConfig)
  Future<String?> updateAccount({
    required String token,
    required int id,
    required String nombre,
    required String apellido,
    required String correo,
  }) async {
    final base = AppConfig.baseUrl;
    final baseClean = base.replaceAll(RegExp(r'\/+$'), '');
    final url = '$baseClean/api/Usuarios/$id';
    final uri = Uri.parse(url);
    final payload = {
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'correo': correo.trim(),
    };

    try {
      // Headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Logging control
      if (AppConfig.httpVerboseLogging) {
        final tokenPreview = token.isEmpty ? '' : token.substring(0, math.min(12, token.length));
        final authLog = AppConfig.httpLogSensitive ? token : '${tokenPreview}...';
        debugPrint('[ACCOUNT][PUT] url: $url');
        debugPrint('[ACCOUNT][PUT] headers: ${jsonEncode({"Authorization": "Bearer $authLog", "Content-Type": "application/json", "Accept": "application/json"})}');
        debugPrint('[ACCOUNT][PUT] body: ${jsonEncode(payload)}');
      }

      final res = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (AppConfig.httpVerboseLogging) {
        debugPrint('[ACCOUNT][PUT] status: ${res.statusCode}');
        debugPrint('[ACCOUNT][PUT] response: ${res.body}');
      }

      if (res.statusCode == 200) {
        // refrescar datos en memoria
        await loadFromToken(token);
        return null;
      }

      if (res.statusCode == 409) {
        final json = jsonDecode(res.body);
        return (json['mensaje'] as String?) ?? 'Correo ya está en uso.';
      }

      if (res.statusCode == 401 || res.statusCode == 403) {
        return 'No autorizado.';
      }

      return 'Error ${res.statusCode} al actualizar.';
    } catch (e, st) {
      debugPrint('[ACCOUNT][PUT][ERR] $e');
      debugPrint('$st');
      return 'Error: $e';
    }
  }
}