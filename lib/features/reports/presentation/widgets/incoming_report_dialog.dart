import 'package:flutter/material.dart';
import '../../../../core/signalr/notificaciones_hub.dart';

class IncomingReportDialog extends StatelessWidget {
  final IncomingReport reporte;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const IncomingReportDialog({
    super.key,
    required this.reporte,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nuevo reporte', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (reporte.fotoUrl != null && reporte.fotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    reporte.fotoUrl!,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 160, height: 160,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Text('Imagen no disponible'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reporte.descripcion?.isNotEmpty == true ? reporte.descripcion! : 'no descripción'),
                    const SizedBox(height: 4),
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
      ),
    );
  }
}