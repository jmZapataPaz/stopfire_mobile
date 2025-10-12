import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/account/presentation/state/account_provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/stations/presentation/pages/stations_map_page.dart';
import 'package:stopfire_mobile/features/shared/widgets/app_bottom_nav_bar.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<AccountProvider>().loadFromToken(token);
      }
    });
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StationsMapPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Información de cuenta')),
      body: ap.loading
          ? const Center(child: CircularProgressIndicator())
          : ap.error != null
              ? Center(child: Text(ap.error!, style: const TextStyle(color: Colors.red)))
              : ap.account == null
                  ? const Center(child: Text('Sin datos'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.badge),
                          title: const Text('Nombre'),
                          subtitle: Text(
                            (() {
                              final nombre = ap.account!.nombre?.trim();
                              final apellido = ap.account!.apellido?.trim();
                              final parts = [
                                if (nombre != null && nombre.isNotEmpty) nombre,
                                if (apellido != null && apellido.isNotEmpty) apellido,
                              ];
                              final full = parts.join(' ');
                              return full.isEmpty ? '-' : full;
                            })(),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Correo'),
                          subtitle: Text(ap.account!.email ?? '-'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Celular'),
                          subtitle: Text(ap.account!.celular ?? '-'),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await context.read<AuthProvider>().logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 2),
    );
  }
}