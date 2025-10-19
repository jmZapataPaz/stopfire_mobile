import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';

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

  int? _myEstacionId;
  void setStationFromToken(String token) {
    try {
      final id = JwtDecoder.getEstacionId(token);
      _myEstacionId = (id != null && id > 0) ? id : null;
      if (kDebugMode) print('[SR] myEstacionId=$_myEstacionId');
    } catch (_) {}
  }

  void Function(int reporteId)? _onReasignado;
  void setOnReasignado(void Function(int reporteId) cb) => _onReasignado = cb;

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

    setStationFromToken(token); // <-- establece la estación del usuario

    void handleNuevo(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      if (kDebugMode) print('[SR][RAW] handleNuevo payload: $p'); 
      if (p is! Map) return;

      // NUEVO: filtra por estación destino (primeraCandidata/estacionId)
      final targetStation = _pickInt(p, ['estacionId','EstacionId','primeraCandidata','PrimeraCandidata']);
      if (_myEstacionId != null && targetStation != null && targetStation != _myEstacionId) {
        if (kDebugMode) print('[SR] Ignorado por estación: target=$targetStation my=$_myEstacionId');
        return;
      }

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

    // NUEVO: cuando alguien rechaza y me reasignan, reaccionar
    void handleRechazado(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      if (kDebugMode) print('[SR][RAW] ReporteRechazado payload: $p');
      if (p is! Map) return;

      // AGREGADO: aceptar múltiples claves de candidata
      final candidata = _pickInt(p, [
        'nuevaCandidata','NuevaCandidata',
        'candidata','Candidata',
        'estacionId','EstacionId',
        'primeraCandidata','PrimeraCandidata',
      ]);

      // id del reporte en varias formas
      final rid = _pickInt(p, ['reporteId','ReporteId','id','Id']);

      if (_myEstacionId != null && candidata != null && rid != null && candidata == _myEstacionId) {
        if (kDebugMode) print('[SR] Reasignado a mi estación, reporteId=$rid (candidata=$candidata)');

        // AGREGADO: si vienen datos completos, emite IncomingReport al stream
        final lat = _pickNum(p, ['latitud','Latitud']);
        final lon = _pickNum(p, ['longitud','Longitud']);
        if (lat != null && lon != null && !_recent.contains(rid)) {
          _recent.add(rid);
          final estado = _pickStr(p, ['estado','Estado'])?.toUpperCase() ?? 'PENDIENTE';
          _incomingCtrl.add(IncomingReport(
            id: rid,
            descripcion: _pickStr(p, ['descripcion','Descripcion']) ?? '',
            fotoUrl: _pickStr(p, ['fotoUrl','FotoUrl']),
            imagenUrl: _pickStr(p, ['imagenUrl','ImagenUrl']),
            latitud: lat,
            longitud: lon,
            estado: estado,
            primeraCandidata: candidata,
            usuarioNombre: _pickStr(p, ['usuarioNombre','UsuarioNombre']),
            usuarioCi: _pickStr(p, ['usuarioCi','UsuarioCi']),
            usuarioCelular: _pickStr(p, ['usuarioCelular','UsuarioCelular']),
            usuarioEmail: _pickStr(p, ['usuarioEmail','UsuarioEmail']),
          ));
          if (kDebugMode) print('[SR][INCOMING][RECHAZADO->MI] id=$rid lat=$lat lon=$lon');
        }

        // Mantiene tu flujo actual: notifica al UI por callback
        _onReasignado?.call(rid);
      }
    }

    conn.on('ReporteCreado', handleNuevo);
    conn.on('ReporteAsignado', handleNuevo);
    conn.on('AsignacionCreada', handleNuevo);
    conn.on('ReporteEstado', handleEstado);
    // NUEVO: soporta variantes de evento de rechazo
    conn.on('ReporteRechazado', handleRechazado);
    conn.on('reporterechazado', handleRechazado); // AGREGADO

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