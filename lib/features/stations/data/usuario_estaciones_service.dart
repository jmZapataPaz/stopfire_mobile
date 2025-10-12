import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stopfire_mobile/core/config/app_config.dart';

class UsuarioEstacion {
  final int id;
  final String? nombre;
  final String? descripcionDireccion;
  final String? celular;
  final double? latitud;
  final double? longitud;

  UsuarioEstacion({
    required this.id,
    this.nombre,
    this.descripcionDireccion,
    this.celular,
    this.latitud,
    this.longitud,
  });

  factory UsuarioEstacion.fromJson(Map<String, dynamic> j) => UsuarioEstacion(
        id: j['id'] as int,
        nombre: j['nombre'] as String?,
        descripcionDireccion: j['descripcionDireccion'] as String?,
        celular: j['celular'] as String?,
        latitud: j['latitud'] == null ? null : double.tryParse(j['latitud'].toString()),
        longitud: j['longitud'] == null ? null : double.tryParse(j['longitud'].toString()),
      );
}

class UsuarioEstacionesService {
  static Future<List<UsuarioEstacion>> getAll({String? token}) async {
    final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
    final uri = Uri.parse('$base/api/Usuarios/estaciones');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final res = await http.get(uri, headers: headers);
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode} $uri -> ${res.body}');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => UsuarioEstacion.fromJson(e as Map<String, dynamic>)).toList();
  }
}