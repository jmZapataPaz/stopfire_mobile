import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stopfire_mobile/core/config/app_config.dart';
import 'dart:convert';
import '../../domain/entities/report_history.dart';

class ReportHistoryRemoteDataSource {
  Future<List<ReportHistory>> fetchHistorial(int idEstacion, String token) async {
    final url = '${AppConfig.baseUrl}/api/Bombero/estaciones/$idEstacion/historial-aceptados';
    debugPrint('[HISTORIAL] GET $url');
    final res = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    debugPrint('[HISTORIAL] status: ${res.statusCode}');
    debugPrint('[HISTORIAL] body: ${res.body}');
    if (res.statusCode != 200) throw Exception('Error al cargar historial: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((j) => ReportHistory.fromJson(j)).toList();
  }
}