import 'dart:async';
import 'dart:developer';
import 'package:signalr_core/signalr_core.dart';

typedef VoidAsync = Future<void> Function();
typedef ReporteIdHandler = Future<void> Function(int id);
typedef ReporteEstadoHandler = Future<void> Function(int id, String estado);
typedef ReporteConfirmadoHandler = void Function(dynamic payload);

class NotificacionesHub {
  NotificacionesHub._();
  static final NotificacionesHub instance = NotificacionesHub._();

  HubConnection? _conn;
  String? _baseUrl;
  String? _token;
  bool _handlersReady = false;
  VoidAsync? _reloadAccepted;
  ReporteIdHandler? _onReporteMitigado;
  ReporteEstadoHandler? _onReporteEstado;
  ReporteConfirmadoHandler? _onReporteConfirmado;

  Future<void> ensureConnected({
    required String baseUrl,
    required String token,
  }) async {
    if (_conn != null &&
        _conn!.state == HubConnectionState.connected &&
        _baseUrl == baseUrl &&
        _token == token) {
      return;
    }
    _baseUrl = baseUrl;
    _token = token;
    await _conn?.stop();
    _handlersReady = false; // <- AGREGADO: forzar re-registro de handlers al reconectar

    _conn = HubConnectionBuilder()
        .withUrl(
          '$baseUrl/hubs/notificaciones',
          HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.webSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _registerHandlers();
    await _conn!.start();
    log('[SR] connected -> ${_conn!.state!.name}');
  }

  void _registerHandlers() {
    if (_conn == null || _handlersReady) return;
    _handlersReady = true;

    void onAnyAsignacion(List<Object?>? args, String evt) async {
      log('[SR] $evt ${args?.isNotEmpty == true ? args!.first : '(sin payload)'}');
      if (_reloadAccepted != null) {
        try { await _reloadAccepted!(); } catch (_) {}
      }
    }
    _conn!.on('AsignacionCreada', (args) => onAnyAsignacion(args, 'AsignacionCreada'));
    _conn!.on('AsignacionActualizada', (args) => onAnyAsignacion(args, 'AsignacionActualizada'));
    _conn!.on('AsignacionEliminada', (args) => onAnyAsignacion(args, 'AsignacionEliminada'));
    _conn!.on('ReporteMitigado', (args) async {
      final id = _extractId(args);
      if (id != null && _onReporteMitigado != null) {
        try { await _onReporteMitigado!(id); } catch (_) {}
      } else if (_reloadAccepted != null) {
        try { await _reloadAccepted!(); } catch (_) {}
      }
    });

    _conn!.on('ReporteEstado', (args) async {
      final id = _extractId(args);
      final estado = _extractString(args, 'Estado') ?? _extractString(args, 'estado') ?? '';
      if (id != null && _onReporteEstado != null) {
        try { await _onReporteEstado!(id, estado); } catch (_) {}
      } else if (_reloadAccepted != null) {
        try { await _reloadAccepted!(); } catch (_) {}
      }
    });

    _conn!.on('ReporteAsignado', (args) => onAnyAsignacion(args, 'ReporteAsignado'));
    _conn?.on('ReporteConfirmado', (args) {
      final payload = (args!.isNotEmpty) ? args[0] : null;
      log('[SR] ReporteConfirmado $payload');
      _onReporteConfirmado?.call(payload);
    });
  }
  void setReloadAccepted(VoidAsync? fn) {
    _reloadAccepted = fn;
  }
  void setOnReporteMitigado(ReporteIdHandler? fn) {
    _onReporteMitigado = fn;
  }
  void setOnReporteEstado(ReporteEstadoHandler? fn) {
    _onReporteEstado = fn;
  }
  void setOnReporteConfirmado(ReporteConfirmadoHandler? h) {
    _onReporteConfirmado = h;
  }

  int? _extractId(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final a0 = args.first;
    if (a0 is Map) {
      final m = Map.from(a0);
      final v = m['Id'] ?? m['id'] ?? m['ReporteId'] ?? m['reporteId'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      if (v is num) return v.toInt();
    }
    return null;
  }

  String? _extractString(List<Object?>? args, String key) {
    if (args == null || args.isEmpty) return null;
    final a0 = args.first;
    if (a0 is Map) {
      final m = Map.from(a0);
      final v = m[key];
      return v?.toString();
    }
    return null;
  }

  Future<void> stop() async {
    try { await _conn?.stop(); } catch (_) {}
    _handlersReady = false;
  }
}