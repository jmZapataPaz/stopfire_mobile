import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';

class IncomingReport {
  final int id;
  final String? descripcion;
  final String? fotoUrl;
  final double latitud;
  final double longitud;
  final String? estado;
  IncomingReport({
    required this.id,
    this.descripcion,
    this.fotoUrl,
    required this.latitud,
    required this.longitud,
    this.estado,
  });
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
      if (p is! Map) return;
      final id = _pickInt(p, ['id', 'Id', 'reporteId', 'ReporteId']);
      final estado = _pickStr(p, ['estado', 'Estado'])?.toUpperCase();
      // No abrir modal por “ACEPTADO”
      if (estado == 'ACEPTADO') { _emitEstado(p); return; }
      final lat = _pickNum(p, ['latitud', 'Latitud']);
      final lon = _pickNum(p, ['longitud', 'Longitud']);
      if (id == null || lat == null || lon == null) return;
      if (_recent.contains(id)) return;
      _recent.add(id);
      _incomingCtrl.add(IncomingReport(
        id: id,
        descripcion: _pickStr(p, ['descripcion', 'Descripcion']),
        fotoUrl: _pickStr(p, ['fotoUrl', 'FotoUrl']),
        latitud: lat,
        longitud: lon,
        estado: estado,
      ));
      if (kDebugMode) print('[SR] nuevo reporte id=$id estado=$estado');
    }

    void handleEstado(dynamic args) {
      final p = (args is List && args.isNotEmpty) ? args.first : args;
      _emitEstado(p);
    }

    conn.on('ReporteCreado', handleNuevo);
    conn.on('ReporteAsignado', handleNuevo);
    conn.on('AsignacionCreada', handleNuevo);

    // Importante: mismos eventos que usa web para MITIGADO/cambios
    conn.on('ReporteEstado', handleEstado);
    conn.on('AsignacionEstado', handleEstado);
    conn.on('ReporteMitigado', handleEstado);
    conn.on('AsignacionMitigada', handleEstado);
    conn.on('ReporteActualizado', handleEstado);
    conn.on('AsignacionActualizada', handleEstado);

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