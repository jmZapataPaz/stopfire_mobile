import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';
import 'package:stopfire_mobile/features/reports/data/provider/report_history_provider.dart';
import 'package:stopfire_mobile/index.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/shared/widgets/app_bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class ReportHistoryPage extends StatelessWidget {
  const ReportHistoryPage({super.key, required idEstacion});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token ?? '';
    final idEstacion = JwtDecoder.getEstacionId(token);

    return ChangeNotifierProvider(
      create: (_) => ReportHistoryProvider()..load(idEstacion!, token),
      child: Consumer<ReportHistoryProvider>(
        builder: (context, p, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Historial de reportes')),
            body: () {
              if (p.loading) return const Center(child: CircularProgressIndicator());
              if (p.error != null) return Center(child: Text(p.error!, style: TextStyle(color: Colors.red)));
              if (p.items.isEmpty) return const Center(child: Text('Sin historial'));
              final dateFormat = DateFormat('HH:mm dd/MM/yy');
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: p.items.length,
                itemBuilder: (context, i) {
                  final r = p.items[i];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: const Color(0xFFFFF1ED), // Card #FFF1ED
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: const Color(0xFFFFF1ED), // Modal #FFF1ED
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    r.descripcion.isNotEmpty ? r.descripcion : 'Sin Descripción',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  if (r.fotoUrl.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        r.fotoUrl.replaceFirst('localhost', Uri.parse(AppConfig.baseUrl).host),
                                        width: 260,
                                        height: 260,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 260, height: 260,
                                          alignment: Alignment.center,
                                          color: Colors.grey.shade200,
                                          child: const Text('Imagen no disponible'),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rowLabelValue('Descripción', r.descripcion.isNotEmpty ? r.descripcion : 'Sin Descripción'),
                            const SizedBox(height: 8),
                            _rowLabelValue('Persona', r.nombreCompleto),
                            const SizedBox(height: 8),
                            _rowLabelValue('CI', r.ci),
                            const SizedBox(height: 8),
                            _rowLabelValue('Celular', r.celular),
                            const SizedBox(height: 8),
                            _rowLabelValue('Fecha', dateFormat.format(r.fechaCreacion)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }(),
            bottomNavigationBar: const AppBottomNavBar(selectedIndex: 1),
          );
        },
      ),
    );
  }

  Widget _rowLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}