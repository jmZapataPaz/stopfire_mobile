import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/shared/widgets/app_bottom_nav_bar.dart';
import 'package:stopfire_mobile/features/stations/presentation/state/citizen_stations_provider.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/stations_map_page.dart';

class CitizenStationsPage extends StatelessWidget {
  const CitizenStationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token;
    return ChangeNotifierProvider(
      create: (_) => CitizenStationsProvider()..load(token: token),
      child: Scaffold(
        appBar: AppBar(title: const Text('Estaciones')),
        bottomNavigationBar: const AppBottomNavBar(selectedIndex: 1),
        body: Consumer<CitizenStationsProvider>(
          builder: (context, p, _) {
            if (p.loading) return const Center(child: CircularProgressIndicator());
            if (p.error != null) {
              return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(p.error!, textAlign: TextAlign.center)));
            }
            if (p.estaciones.isEmpty) {
              return const Center(child: Text('Sin estaciones'));
            }
            return RefreshIndicator(
              onRefresh: () => p.load(token: token),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: p.estaciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = p.estaciones[i];
                  return InkWell(
                    onTap: () {
                      final lat = e.latitud;
                      final lon = e.longitud;
                      if (lat != null && lon != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => StationsMapPage(
                              focusLat: lat,
                              focusLng: lon,
                              focusZoom: 15.5,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Esta estación no tiene ubicación disponible')),
                        );
                      }
                    },
                    child: Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.nombre ?? 'Sin nombre', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            if ((e.descripcionDireccion ?? '').isNotEmpty)
                              Text(e.descripcionDireccion!, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(e.celular ?? '-', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}