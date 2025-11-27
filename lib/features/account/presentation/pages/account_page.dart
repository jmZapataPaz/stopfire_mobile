import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';
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

  // Bottom sheet para actualizar nombre, apellido y correo (con logs y AppConfig)
  Future<void> _openUpdateSheet() async {
    final ap = context.read<AccountProvider>();
    final auth = context.read<AuthProvider>();
    if (ap.account == null || auth.token == null) return;

    final nombreCtrl = TextEditingController(text: ap.account!.nombre ?? '');
    final apellidoCtrl = TextEditingController(text: ap.account!.apellido ?? '');
    final celularCtrl = TextEditingController(text: ap.account!.celular ?? ''); // CAMBIO: ahora celular
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Actualizar información', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: apellidoCtrl,
                        decoration: const InputDecoration(labelText: 'Apellido'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: celularCtrl,
                        decoration: const InputDecoration(labelText: 'Celular'),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Requerido';
                          if (!RegExp(r'^[0-9]{8,15}$').hasMatch(s)) return 'Solo dígitos (8-15)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;

                                      setState(() => saving = true);
                                      final err = await context.read<AccountProvider>().updateAccount(
                                        token: auth.token!,
                                        id: ap.account!.id!,
                                        nombre: nombreCtrl.text,
                                        apellido: apellidoCtrl.text,
                                        celular: celularCtrl.text, // CAMBIO
                                      );
                                      setState(() => saving = false);

                                      if (!mounted) return;
                                      if (err == null) {
                                        Navigator.pop(ctx, true);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(err), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                              child: saving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((ok) {
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información actualizada')),
        );
      }
    });
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
                        const SizedBox(height: 12),
                        // ÚNICO botón para actualizar (abre bottom sheet con logs y AppConfig)
                        ElevatedButton.icon(
                          onPressed: _openUpdateSheet,
                          icon: const Icon(Icons.edit),
                          label: const Text('Actualizar información'),
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