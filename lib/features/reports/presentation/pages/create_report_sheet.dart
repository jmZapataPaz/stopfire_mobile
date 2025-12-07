import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/reports/presentation/state/report_provider.dart';

class CreateReportSheet extends StatelessWidget {
  const CreateReportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final auth = context.read<AuthProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.report, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text('Reportar Incidente', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoBox(file: provider.photo, onTap: () => provider.takePhoto()),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => provider.descripcionSetter = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.error != null)
              Text(_cleanError(provider.error!), style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (provider.sending || provider.photo == null)
                    ? null
                    : () async {
                        final auth = context.read<AuthProvider>();
                        final rp = context.read<ReportProvider>();
                        final token = auth.token;
                        if (token == null || token.isEmpty) return;

                        try {
                          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) throw Exception('GPS desactivado');

                          var permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                          }
                          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                            throw Exception('Permiso de ubicación denegado');
                          }

                          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                          final lat = pos.latitude;
                          final lon = pos.longitude;

                          final base = AppConfig.baseUrl.replaceAll(RegExp(r'\/$'), '');
                          final uri = Uri.parse('$base/api/Usuarios/reportes').replace(queryParameters: {
                            'estado': 'PENDIENTE',
                            'lat': lat.toString(),
                            'lon': lon.toString(),
                            'radiusMeters': '2000',
                          });
                          final res = await http.get(uri, headers: {
                            'Authorization': 'Bearer $token',
                            'Accept': 'application/json',
                          });

                          if (res.statusCode >= 200 && res.statusCode < 300) {
                            final body = jsonDecode(res.body);
                            if (body is List && body.isNotEmpty) {
                              final nearest = Map<String, dynamic>.from(body.first as Map);
                              final nearestId = (nearest['id'] ?? nearest['Id']) as int;
                              final confirmCount = (nearest['confirmaciones'] ?? nearest['Confirmaciones'] ?? 1) as int;
                              final riesgo = (nearest['riesgoPercent'] ?? nearest['RiesgoPercent'] ?? (confirmCount * 20)) as int;

                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Incidente cercano'),
                                  content: Text('Ya existe un incidente cerca (confirmaciones: $confirmCount, riesgo: $riesgo%). ¿Confirmar que sigue ocurriendo?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                    FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
                                  ],
                                ),
                              );

                              if (ok == true) {
                                final cUri = Uri.parse('$base/api/Usuarios/reportes/$nearestId/confirm');
                                final cRes = await http.post(cUri, headers: {
                                  'Authorization': 'Bearer $token',
                                  'Accept': 'application/json',
                                });
                                
                                if (cRes.statusCode >= 200 && cRes.statusCode < 300) {
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true); 
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gracias, confirmaste el incidente.'))
                                    );
                                  }
                                  return;
                                } else if (cRes.statusCode == 409) {
                                  // Conflicto: ya confirmó anteriormente
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ya confirmaste este incidente. Aguarda la llegada de los bomberos.'),
                                        duration: Duration(seconds: 4),
                                      )
                                    );
                                  }
                                  return;
                                } else {
                                  if (context.mounted) {
                                    // Intentar leer el mensaje del servidor
                                    String errorMsg = 'Error al confirmar: ${cRes.statusCode}';
                                    try {
                                      final errorBody = jsonDecode(cRes.body);
                                      if (errorBody is Map && errorBody.containsKey('mensaje')) {
                                        errorMsg = errorBody['mensaje'];
                                      }
                                    } catch (_) {}
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(errorMsg))
                                    );
                                  }
                                  return;
                                }
                              } else {
                                return;
                              }
                            }
                          } else {
                          }
                        } catch (_) {
                        }
                        try {
                          await provider.submit(token: token);
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                icon: provider.sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  const _PhotoBox({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = 120.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.03),
        ),
        child: file == null
            ? const Center(child: Icon(Icons.camera_alt, size: 40))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}

String _cleanError(String raw) {
    final s = raw.trim();
    final prefix = RegExp(r'^HTTP\s+\d{3}:\s*').firstMatch(s);
    final noPrefix = prefix != null ? s.substring(prefix.end).trim() : s;
    try {
      if (noPrefix.startsWith('{')) {
        final map = (const JsonDecoder()).convert(noPrefix) as Map;
        final m = map['mensaje'];
        if (m is String && m.trim().isNotEmpty) return m.trim();
      }
    } catch (_) {}
    final quoted = RegExp(r'^\{?\s*"?mensaje"?\s*:\s*"([^"]+)"\s*\}?$').firstMatch(noPrefix);
    if (quoted != null) return quoted.group(1)!.trim();
    return noPrefix;
  }