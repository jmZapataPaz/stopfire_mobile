import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/features/reports/data/models/report_model.dart';

// NUEVO: helper simple para geocodificación inversa (no interfiere con lo existente)
Future<String?> _reverseGeocode(String latStr, String lngStr) async {
  try {
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lngStr);
    if (lat == null || lon == null) return null;
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18&addressdetails=1&accept-language=es',
    );
    // AGREGADO: User-Agent recomendado por Nominatim + email opcional
    final res = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'stopfire-mobile/1.0 (+https://tu-dominio.example)',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      print('[GEOCODE] status=${res.statusCode} body=${res.body}');
      return null;
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    final a = (j['address'] ?? {}) as Map<String, dynamic>;
    final via = a['road'] ?? a['pedestrian'] ?? a['cycleway'] ?? a['footway'] ?? a['path'] ?? a['neighbourhood'];
    final localidad = a['suburb'] ?? a['village'] ?? a['town'] ?? a['city'];
    final texto = [via, localidad].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    final out = (texto.isNotEmpty ? texto : (j['display_name'] as String?));
    print('[GEOCODE] lat=$lat lon=$lon -> "$out"');
    return out;
  } catch (e) {
    print('[GEOCODE] error: $e');
    return null;
  }
}

class ReportRemoteDataSource {
  Future<void> createReport({
    required String token,
    required String descripcion,
    required String lat,
    required String lng,
    required File photo,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.reportCreateEndpoint}');
    final req = http.MultipartRequest('POST', uri);

    req.headers['Authorization'] = 'Bearer $token';
    req.fields['Descripcion'] = descripcion;
    req.fields['Latitud'] = lat;
    req.fields['Longitud'] = lng;

    final direccion = await _reverseGeocode(lat, lng);
    if (direccion != null && direccion.trim().isNotEmpty) {
      req.fields['Direccion'] = direccion.trim();
    } else {
      print('[REPORT] Sin direccion obtenida (se enviará vacío)');
    }

    File upload = photo;
    final ext = p.extension(upload.path).toLowerCase();
    MediaType ct;
    if (ext == '.png') {
      ct = MediaType('image', 'png');
    } else if (ext == '.jpg' || ext == '.jpeg') {
      ct = MediaType('image', 'jpeg');
    } else {
      ct = MediaType('image', 'jpeg');
      final newPath = upload.path.replaceAll(RegExp(r'\.[^\.]+$'), '.jpg');
      if (newPath != upload.path) {
        try { upload = await upload.copy(newPath); } catch (_) {}
      }
    }

    req.files.add(await http.MultipartFile.fromPath(
      'Foto',
      upload.path,
      contentType: ct,
      filename: p.basename(upload.path),
    ));
    final masked = _maskToken(token);
    final sizeBytes = await upload.length();
    print('[REPORT][REQ] POST $uri');
    print('[REPORT][REQ] Headers: { Authorization: Bearer $masked }');
    print('[REPORT][REQ] Fields: ${req.fields}');
    print('[REPORT][REQ] File: Foto=@${upload.path} (${(sizeBytes/1024).toStringAsFixed(1)} KB) ct=$ct');
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    print('[REPORT][RES] Status: ${res.statusCode}');
    print('[REPORT][RES] Headers: ${res.headers}');
    final body = res.body;
    print('[REPORT][RES] Body: ${body.length > 2000 ? body.substring(0, 2000) + '...<truncated>' : body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Fallo creando reporte (${res.statusCode})');
    }
  }

  Future<List<ReportModel>> getReports({required String token}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.reportCreateEndpoint}');
    final res = await http.get(
      uri,
      headers: { 'Authorization': 'Bearer $token', 'Accept': 'application/json' },
    );
    print('[REPORT][LIST][REQ] GET $uri');
    print('[REPORT][LIST][RES] ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error cargando reportes (${res.statusCode})');
    }
    final data = json.decode(res.body);
    if (data is! List) return [];
    return data.map<ReportModel>((e) => ReportModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  String _maskToken(String t) =>
      t.length <= 16 ? '${t.substring(0, t.length ~/ 2)}...' : '${t.substring(0, 12)}...${t.substring(t.length - 4)}';
}