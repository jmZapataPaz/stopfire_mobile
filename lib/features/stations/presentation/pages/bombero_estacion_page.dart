import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/stations/presentation/state/bombero_estacion_provider.dart';
import 'package:stopfire_mobile/features/shared/widgets/app_bottom_nav_bar.dart';
import 'package:stopfire_mobile/index.dart'; 

class BomberoEstacionPage extends StatelessWidget {
  const BomberoEstacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final token = context.read<AuthProvider>().token!;
    return ChangeNotifierProvider(
      create: (_) => BomberoEstacionProvider(token: token)..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<BomberoEstacionProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Estación')),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 2),
      body: Column(
        children: [
          Expanded(
            child: p.loading
                ? const Center(child: CircularProgressIndicator())
                : p.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_cleanError(p.error!), textAlign: TextAlign.center),
                        ),
                      )
                    : p.estacion == null
                        ? const Center(child: Text('No tienes estación asignada'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Card(
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _rowLabelValue('Nombre', p.estacion!.nombre ?? '-'),
                                        const SizedBox(height: 8),
                                        _rowLabelValue('Descripción dirección', p.estacion!.descripcionDireccion ?? '-'),
                                        const SizedBox(height: 8),
                                        _rowLabelValue('Celular', p.estacion!.celular ?? '-'),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton(
                                    onPressed: p.toggleEdit,
                                    child: Text(p.editMode ? 'Cancelar' : 'Actualizar información'),
                                  ),
                                ),
                                if (p.editMode) ...[
                                  const SizedBox(height: 12),
                                  Card(
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          TextField(
                                            decoration: const InputDecoration(labelText: 'Nombre'),
                                            controller: TextEditingController(text: p.nombre)
                                              ..selection = TextSelection.fromPosition(TextPosition(offset: p.nombre.length)),
                                            onChanged: (v) => p.nombre = v,
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            decoration: const InputDecoration(labelText: 'Descripción dirección'),
                                            maxLines: 3,
                                            controller: TextEditingController(text: p.descripcionDireccion)
                                              ..selection = TextSelection.fromPosition(TextPosition(offset: p.descripcionDireccion.length)),
                                            onChanged: (v) => p.descripcionDireccion = v,
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            decoration: const InputDecoration(labelText: 'Celular'),
                                            keyboardType: TextInputType.phone,
                                            controller: TextEditingController(text: p.celular)
                                              ..selection = TextSelection.fromPosition(TextPosition(offset: p.celular.length)),
                                            onChanged: (v) => p.celular = v,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                onPressed: p.toggleEdit,
                                                child: const Text('Cancelar'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: p.saving ? null : () async {
                                                  final ok = await p.save();
                                                  if (ok && context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Estación actualizada')),
                                                    );
                                                  }
                                                },
                                                child: p.saving
                                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : const Text('Guardar'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Center(
              child: SizedBox(
                width: 260,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  onPressed: () async {
                    try {
                      await context.read<AuthProvider>().logout(); 
                    } catch (_) {
                    }
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
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

}