import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LastLoginRecorder {
  static const _storage = FlutterSecureStorage();
  static const _key = 'ultimo_ingreso_iso';

  static Future<void> recordFromLoginResponse(Map<String, dynamic> json) async {
    try {
      final u = json['usuario'] as Map<String, dynamic>?;
      final v = u?['ultimoIngreso'] ?? u?['UltimoIngreso'];
      if (v == null) return;
      final iso = v.toString(); 
      await _storage.write(key: _key, value: iso);
    } catch (_) {
    }
  }

  static Future<String?> read() => _storage.read(key: _key);
  static Future<void> clear() => _storage.delete(key: _key);

  // NUEVO: registrar la hora actual (ISO) cuando se salta el login por token guardado
  static Future<void> recordNow() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _storage.write(key: _key, value: nowIso);
  }
}