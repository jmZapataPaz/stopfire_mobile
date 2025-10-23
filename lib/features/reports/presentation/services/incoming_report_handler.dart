import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stopfire_mobile/core/config/app_config.dart';
import '../../../../core/signalr/notificaciones_hub.dart';
import 'package:flutter/scheduler.dart'; 

typedef TokenProvider = Future<String?> Function();

class IncomingReportHandler {
  IncomingReportHandler({
    required this.navigatorKey,
    required this.apiBase,
    required this.tokenProvider,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String apiBase;
  final TokenProvider tokenProvider;

  bool _dialogOpen = false;
  int? _currentDialogReportId;

  Future<String?> showIncoming(IncomingReport r) async {
    if (_dialogOpen) return null;
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) return null;

    _dialogOpen = true;
    _currentDialogReportId = r.id;

    // AGREGADO: cierre seguro (evita doble pop)
    void _safeClose() {
      if (!_dialogOpen) return;
      _dialogOpen = false;
      if (navigatorKey.currentState?.canPop() ?? false) {
        navigatorKey.currentState?.pop();
      }
    }

    int? _pickReporteId(Object rechazo) {
      // ...existing code...
    }

    final notificacionesHub = NotificacionesHub.instance;
    final estadoSub = notificacionesHub.reportEstadoStream.listen((estado) {
      if (!_dialogOpen) return;
      if (_currentDialogReportId == null) return;
      if (estado.id == _currentDialogReportId &&
          (estado.estado == 'ACEPTADO' || estado.estado == 'MITIGADO')) {
        _safeClose(); // único cierre cuando viene de web/otro cliente
      }
    });
    final rechazoSub = notificacionesHub.reportRechazadoStream.listen((rechazo) {
      if (!_dialogOpen) return;
      if (_currentDialogReportId == null) return;
      final rid = _pickReporteId(rechazo);
      if (rid == _currentDialogReportId) {
        _safeClose(); // cierre por rechazo desde web/otro cliente
      }
    });

    String? result;
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: _Dialog(
          reporte: r,
          onAccept: () async {
            // Cierra localmente tras confirmar en backend
            try { await acceptReport(r.id); result = 'accepted'; } catch (_) {}
            _safeClose();
          },
          onReject: () async {
            // Cierra localmente tras confirmar en backend
            try { await rejectReport(r.id); result = 'rejected'; } catch (_) {}
            _safeClose();
          },
        ),
      ),
    );
    _dialogOpen = false;
    _currentDialogReportId = null;
    await estadoSub.cancel();
    await rechazoSub.cancel();
    return result;
  }

  Future<void> acceptReport(int id) async {
    final t = await tokenProvider();
    if (t == null) return;
    final uri = Uri.parse('$apiBase/api/Bombero/reportes/$id/aceptar');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $t',
      'Accept': 'application/json',
    });
    if (res.statusCode >= 400) {
      throw Exception('Aceptar ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> rejectReport(int id) async {
    final t = await tokenProvider();
    if (t == null) return;
    final uri = Uri.parse('$apiBase/api/Bombero/reportes/$id/rechazar');
    final res = await http.post(uri, headers: {
      'Authorization': 'Bearer $t',
      'Accept': 'application/json',
    });
    if (res.statusCode >= 400) {
      throw Exception('Rechazar ${res.statusCode}: ${res.body}');
    }
  }
}

String normalizeImageUrl(String? raw) {
  if (raw == null || raw.isEmpty) return 'nada';
  try {
    final base = Uri.parse(AppConfig.baseUrl);
    Uri u = Uri.parse(raw);
    if (!u.hasScheme) {
      return base.resolveUri(u).toString();
    }
    if (u.host == 'localhost' || u.host == '127.0.0.1') {
      return u.replace(scheme: base.scheme, host: base.host, port: base.port).toString();
    }
    return u.toString();
  } catch (_) {
    return raw;
  }
}

class _Dialog extends StatefulWidget {
  final IncomingReport reporte;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _Dialog({required this.reporte, required this.onAccept, required this.onReject});

  @override
  State<_Dialog> createState() => _DialogState();
}

class _DialogState extends State<_Dialog> with SingleTickerProviderStateMixin {
  static const int totalSeconds = 60;
  int secondsLeft = totalSeconds;
  late final Ticker _ticker;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: totalSeconds),
    )..forward();
    _ticker = Ticker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final left = totalSeconds - elapsed.inSeconds;
    if (left != secondsLeft && left >= 0) {
      setState(() => secondsLeft = left);
      if (left == 0) {
        widget.onReject();
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = normalizeImageUrl(
      (widget.reporte.imagenUrl?.isNotEmpty ?? false)
        ? widget.reporte.imagenUrl
        : widget.reporte.fotoUrl
    );
    final percent = secondsLeft / totalSeconds;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final animatedPercent = 1.0 - _controller.value;
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: animatedPercent,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.orange, Colors.red]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -22,
                      child: Text('$secondsLeft s', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const Text('Nuevo reporte',style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (fotoUrl.isNotEmpty)
              SizedBox(
                width: 160,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fotoUrl,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160,
                      height: 160,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Text('Imagen no disponible', textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            if (fotoUrl.isEmpty)
              Container(
                width: 160,
                height: 160,
                alignment: Alignment.center,
                color: Colors.grey.shade200,
                child: const Text('Imagen no disponible', textAlign: TextAlign.center),
              ),
            const SizedBox(height: 8),
            if (widget.reporte.usuarioNombre != null ||
                widget.reporte.usuarioCi != null ||
                widget.reporte.usuarioCelular != null ||
                widget.reporte.usuarioEmail != null
              )
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.reporte.descripcion ?? 'Sin descripción'),
                ],
              ),
            ),
            Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información del ciudadano', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (widget.reporte.usuarioNombre != null)
                      Text('Nombre: ${widget.reporte.usuarioNombre!}'),
                    if (widget.reporte.usuarioCi != null)
                      Text('CI: ${widget.reporte.usuarioCi!}'),
                    if (widget.reporte.usuarioCelular != null)
                      Text('Celular: ${widget.reporte.usuarioCelular!}'),
                    if (widget.reporte.usuarioEmail != null)
                      Text('Email: ${widget.reporte.usuarioEmail!}'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: widget.onReject, child: const Text('Rechazar')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onAccept();
                    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}