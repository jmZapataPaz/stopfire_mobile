import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stopfire_mobile/core/config/app_config.dart';

class EstacionDetalle {
  final int id;
  final String? nombre;
  final String? descripcionDireccion;
  final String? celular;
  final double? latitud;
  final double? longitud;

  EstacionDetalle({
    required this.id,
    this.nombre,
    this.descripcionDireccion,
    this.celular,
    this.latitud,
    this.longitud,
  });

  factory EstacionDetalle.fromJson(Map<String, dynamic> j) => EstacionDetalle(
        id: j['id'] as int,
        nombre: j['nombre'] as String?,
        descripcionDireccion: j['descripcionDireccion'] as String?,
        celular: j['celular'] as String?,
        latitud: j['latitud'] == null ? null : double.tryParse(j['latitud'].toString()),
        longitud: j['longitud'] == null ? null : double.tryParse(j['longitud'].toString()),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcionDireccion': descripcionDireccion,
        'celular': celular,
        'latitud': latitud,
        'longitud': longitud,
      };

  @override
  String toString() => jsonEncode(toMap());
}

class EstacionService {
  static String get _base => AppConfig.baseUrl;

  static String _maskToken(String token) {
    if (token.length <= 12) return '${token.substring(0, token.length ~/ 2)}***';
    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }

  static void _logReq({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) {
    debugPrint('[HTTP][$method] $uri');
    debugPrint('[HTTP][Headers] ${jsonEncode(headers)}');
    if (body != null) debugPrint('[HTTP][Body] $body');
  }

  static void _logRes(Uri uri, http.Response r, Duration dt) {
    debugPrint('[HTTP][<-] ${r.statusCode} ${uri.toString()} (${dt.inMilliseconds} ms)');
    debugPrint('[HTTP][Resp headers] ${jsonEncode(r.headers)}');
    debugPrint('[HTTP][Resp body] ${r.body}');
  }

  static String _formatErr(String url, http.Response r) {
    final contentType = r.headers['content-type'] ?? '';
    String body = r.body;
    try {
      if (contentType.contains('application/json')) {
        final json = jsonDecode(r.body);
        if (json is Map && json['message'] != null) {
          body = json['message'].toString();
        } else {
          body = jsonEncode(json);
        }
      }
    } catch (_) {}
    return 'HTTP ${r.statusCode} $url -> $body';
  }

  static Future<EstacionDetalle> getDetalle(String token) async {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
    final uri = Uri.parse('$base/api/Bombero/mi-estacion');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
    final masked = (token.isNotEmpty && token.length > 16)
        ? '${token.substring(0, 8)}...${token.substring(token.length - 8)}'
        : token;
    debugPrint('[HTTP][GET] $uri');
    debugPrint('[HTTP][Headers] ${jsonEncode({...headers, 'Authorization': 'Bearer $masked'})}');

    final res = await http.get(uri, headers: headers);
    debugPrint('[HTTP][<-] ${res.statusCode} $uri');
    if (res.statusCode >= 400) {
      debugPrint('[HTTP][Resp headers] ${jsonEncode(res.headers)}');
      debugPrint('[HTTP][Resp body] ${res.body}');
      throw Exception('HTTP ${res.statusCode} $uri -> ${res.body}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return EstacionDetalle.fromJson(j);
  }

  static Future<EstacionDetalle> actualizar(String token, int estacionId, Map<String, dynamic> cambios) async {
    final uri = Uri.parse('$_base/api/Bombero/estaciones/$estacionId');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final logHeaders = Map<String, String>.from(headers)
      ..update('Authorization', (_) => 'Bearer ${_maskToken(token)}', ifAbsent: () => 'Bearer ${_maskToken(token)}');

    final body = jsonEncode(cambios);
    final t0 = DateTime.now();
    _logReq(method: 'PATCH', uri: uri, headers: logHeaders, body: body);
    final res = await http.patch(uri, headers: headers, body: body);
    final dt = DateTime.now().difference(t0);
    _logRes(uri, res, dt);

    if (res.statusCode == 204 || (res.body.isEmpty && res.statusCode >= 200 && res.statusCode < 300)) {
      debugPrint('[ESTACION][PATCH] 204/empty body -> refrescando detalle');
      return await getDetalle(token);
    }
    if (res.statusCode >= 400) {
      throw Exception(_formatErr(uri.toString(), res));
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final det = EstacionDetalle.fromJson(j);
    debugPrint('[ESTACION][ACTUALIZADA] ${det.toString()}');
    return det;
  }
}