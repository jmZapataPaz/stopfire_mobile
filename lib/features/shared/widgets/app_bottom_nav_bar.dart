import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/core/utils/jwt_decoder.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/account/presentation/pages/account_page.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/report_history_page.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/stations_map_page.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/citizen_stations_page.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/bombero_estacion_page.dart';
import 'dart:developer' as _dart;

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  const AppBottomNavBar({super.key, required this.selectedIndex});

  int? _roleIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final p = jsonDecode(payload) as Map<String, dynamic>;
      final v = p['rol_id'] ?? p['role_id'] ?? p['rolId'] ?? p['roleId'];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token ?? '';
    final idEstacion = JwtDecoder.getEstacionId(token);
    final roleId = _roleIdFromToken(token);
    final isBombero = roleId == 2;

    if (isBombero) {
      final idx = selectedIndex.clamp(0, 2);
      return SafeArea(
        top: false,
        child: BottomAppBar(
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: kBottomNavigationBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SingleNavItem(
                  icon: Icons.map,
                  label: 'Mapa',
                  selected: idx == 0,
                  onTap: () {
                    if (idx != 0) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const StationsMapPage()),
                      );
                    }
                  },
                ),
                _SingleNavItem(
                  icon: Icons.history,
                  label: 'Historial',
                  selected: idx == 1,
                  onTap: () {
                    if (idx != 1) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => ReportHistoryPage(idEstacion: idEstacion!)),
                      );
                    }
                  },
                ),
                _SingleNavItem(
                  icon: Icons.local_fire_department,
                  label: 'Estación',
                  selected: idx == 2,
                  onTap: () {
                    if (idx != 2) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const BomberoEstacionPage()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ciudadano/otros roles -> 3 pestañas
    final idx = selectedIndex.clamp(0, 2);
    return NavigationBar(
      selectedIndex: idx,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
        NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Estaciones'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta'),
      ],
      onDestinationSelected: (i) {
        if (i == 0 && idx != 0) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const StationsMapPage()));
        } else if (i == 1 && idx != 1) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CitizenStationsPage()));
        } else if (i == 2 && idx != 2) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AccountPage()));
        }
      },
    );
  }
}

class _SingleNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _SingleNavItem({required this.icon, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, height: 1)),
          ],
        ),
      ),
    );
  }
}