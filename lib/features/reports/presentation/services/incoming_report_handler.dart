import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/signalr/notificaciones_hub.dart';

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

  Future<String?> showIncoming(IncomingReport r) async {
    if (_dialogOpen) return null;
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) return null;

    _dialogOpen = true;
    String? result;
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: _Dialog(
          reporte: r,
          onAccept: () async {
            try { await acceptReport(r.id); result = 'accepted'; } catch (_) {}
            if (context.mounted) Navigator.of(context).pop();
          },
          onReject: () async {
            try { await rejectReport(r.id); result = 'rejected'; } catch (_) {}
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
    _dialogOpen = false;
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

class _Dialog extends StatelessWidget {
  final IncomingReport reporte;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _Dialog({required this.reporte, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nuevo reporte'),
            const SizedBox(height: 8),
            if (reporte.fotoUrl != null && reporte.fotoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(reporte.fotoUrl!, width: 160, height: 160, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reporte.descripcion ?? 'Sin descripción'),
                  Text('Lat: ${reporte.latitud.toStringAsFixed(6)}'),
                  Text('Lon: ${reporte.longitud.toStringAsFixed(6)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onReject, child: const Text('Rechazar')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onAccept, child: const Text('Aceptar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}