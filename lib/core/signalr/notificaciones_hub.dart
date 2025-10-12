import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';

class IncomingReport {
  final int id;
  final String? descripcion;
  final String? fotoUrl;
  final String? imagenUrl; 
  final double latitud;
  final double longitud;
  final String? estado;
  final int? primeraCandidata;
  final String? usuarioNombre;
  final String? usuarioCi;
  final String? usuarioCelular;
  final String? usuarioEmail;

  IncomingReport({
    required this.id,
    required this.descripcion,
    this.fotoUrl,
    this.imagenUrl, 
    required this.latitud,
    required this.longitud,
    required this.estado,
    this.primeraCandidata,
    this.usuarioNombre,
    this.usuarioCi,
    this.usuarioCelular,
    this.usuarioEmail,
  });

  factory IncomingReport.fromJson(Map<String, dynamic> j) => IncomingReport(
        id: j['id'] ?? j['Id'],
        descripcion: j['descripcion'] ?? j['Descripcion'] ?? '',
        fotoUrl: j['fotoUrl'] ?? j['FotoUrl'],
        imagenUrl: j['imagenUrl'] ?? j['ImagenUrl'], 
        latitud: (j['latitud'] ?? j['Latitud'])?.toDouble(),
        longitud: (j['longitud'] ?? j['Longitud'])?.toDouble(),
        estado: j['estado'] ?? j['Estado'] ?? '',
        primeraCandidata: j['primeraCandidata'],
        usuarioNombre: j['usuarioNombre'],
        usuarioCi: j['usuarioCi'],
        usuarioCelular: j['usuarioCelular'],
        usuarioEmail: j['usuarioEmail'],
      );

}

class ReportStateChange {
  final int id;
  final String? estado;
  ReportStateChange({required this.id, required this.estado});
}

class NotificacionesHub {
  NotificacionesHub._();
  static final NotificacionesHub instance = NotificacionesHub._();

  HubConnection? _conn;
  final _incomingCtrl = StreamController<IncomingReport>.broadcast();
  Stream<IncomingReport> get incomingReports => _incomingCtrl.stream;

  final _estadoCtrl = StreamController<ReportStateChange>.broadcast();
  Stream<ReportStateChange> get estadoChanges => _estadoCtrl.stream;

  final _reportEstadoCtrl = StreamController<ReportEstado>.broadcast();
  Stream<ReportEstado> get reportEstadoStream => _reportEstadoCtrl.stream;

  final _reportRechazadoCtrl = StreamController<ReporteRechazado>.broadcast();
  Stream<ReporteRechazado> get reportRechazadoStream => _reportRechazadoCtrl.stream;

  final Set<int> _recent = <int>{};

  bool get isConnected => _conn?.state == HubConnectionState.connected;

  Future<void> ensureConnected({required String baseUrl, required String token}) async {
    if (_conn != null && _conn!.state != HubConnectionState.disconnected) {
      if (_conn!.state == HubConnectionState.connected) return;
      try { await _conn!.start(); return; } catch (_) {}
    }

    final url = '${baseUrl.replaceAll(RegExp(r'\/$'), '')}/hubs/notificaciones';
    final conn = HubConnectionBuilder()
        .withUrl(url, HttpConnectionOptions(
          accessTokenFactory: () async => token,
          transport: HttpTransportType.webSockets,
        ))
        .withAutomaticReconnect()
        .build();

    void handleNuevo(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      if (kDebugMode) print('[SR][RAW] handleNuevo payload: $p'); 
      if (p is! Map) return;
      final id = _pickInt(p, ['id', 'Id', 'reporteId', 'ReporteId']);
      final estado = _pickStr(p, ['estado', 'Estado'])?.toUpperCase();
      if (estado == 'ACEPTADO') { _emitEstado(p); return; }
      final lat = _pickNum(p, ['latitud', 'Latitud']);
      final lon = _pickNum(p, ['longitud', 'Longitud']);
      if (id == null || lat == null || lon == null) return;
      if (_recent.contains(id)) return;
      _recent.add(id);
      if (kDebugMode) print('[SR][PARSED] id=$id estado=$estado lat=$lat lon=$lon');
      _incomingCtrl.add(IncomingReport(
        id: id,
        descripcion: _pickStr(p, ['descripcion', 'Descripcion']),
        fotoUrl: _pickStr(p, ['fotoUrl', 'FotoUrl']),
        latitud: lat,
        imagenUrl: _pickStr(p, ['imagenUrl', 'ImagenUrl']),
        longitud: lon,
        estado: estado,
        primeraCandidata: _pickInt(p, ['primeraCandidata', 'PrimeraCandidata']),
        usuarioNombre: _pickStr(p, ['usuarioNombre', 'UsuarioNombre']),
        usuarioCi: _pickStr(p, ['usuarioCi', 'UsuarioCi']),
        usuarioCelular: _pickStr(p, ['usuarioCelular', 'UsuarioCelular']),
        usuarioEmail: _pickStr(p, ['usuarioEmail', 'UsuarioEmail']),
      ));
      if (kDebugMode) print('[SR][INCOMING] usuarioNombre=${_pickStr(p, ['usuarioNombre', 'UsuarioNombre'])} usuarioCelular=${_pickStr(p, ['usuarioCelular', 'UsuarioCelular'])}');
    }

    void handleEstado(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      if (p is! Map) return;
      final id = p['id'] ?? p['Id'] ?? p['reporteId'] ?? p['ReporteId'];
      final estado = (p['estado'] ?? p['Estado'] ?? '').toString().toUpperCase();
      _reportEstadoCtrl.add(ReportEstado(id: id, estado: estado));
    }

    void handleRechazado(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      if (p is! Map) return;
      final reporteId = p['reporteId'] ?? p['ReporteId'];
      _reportRechazadoCtrl.add(ReporteRechazado(reporteId: reporteId));
    }

    conn.on('ReporteCreado', handleNuevo);
    conn.on('ReporteAsignado', handleNuevo);
    conn.on('AsignacionCreada', handleNuevo);
    conn.on('ReporteEstado', handleEstado);
    conn.on('AsignacionEstado', handleEstado);
    conn.on('ReporteMitigado', handleEstado);
    conn.on('AsignacionMitigada', handleEstado);
    conn.on('ReporteActualizado', handleEstado);
    conn.on('AsignacionActualizada', handleEstado);
    conn.on('ReporteRechazado', handleRechazado);

    _conn = conn;
    await conn.start();
    if (kDebugMode) print('[SR] connected -> $url');
  }

  void _emitEstado(dynamic p) {
    if (p is! Map) return;
    final id = _pickInt(p, ['id', 'Id', 'reporteId', 'ReporteId']);
    final estado = _pickStr(p, ['estado', 'Estado'])?.toUpperCase();
    if (id == null) return;
    if (kDebugMode) print('[SR] estado cambio id=$id -> $estado');
    _estadoCtrl.add(ReportStateChange(id: id, estado: estado));
  }
}

class ReportEstado {
  final int? id;
  final String estado;
  ReportEstado({this.id, required this.estado});
}

class ReporteRechazado {
  final int? reporteId;
  ReporteRechazado({this.reporteId});
}

int? _pickInt(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    if (v is int) return v;
    final p = int.tryParse('$v');
    if (p != null) return p;
  }
  return null;
}
double? _pickNum(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    final p = double.tryParse('$v');
    if (p != null) return p;
  }
  return null;
}
String? _pickStr(Map m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v != null) return v.toString();
  }
  return null;
}