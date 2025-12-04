import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/pages/forgot_password_verify_page.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/password_recover_provider.dart';

class ForgotPasswordEmailPage extends StatefulWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  State<ForgotPasswordEmailPage> createState() => _ForgotPasswordEmailPageState();
}

class _ForgotPasswordEmailPageState extends State<ForgotPasswordEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();

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
    final m2 = RegExp(r'^\{?\s*"?mensaje"?\s*:\s*"([^"]+)"\s*\}?$').firstMatch(noPrefix);
    if (m2 != null) return m2.group(1)!.trim();
    return noPrefix;
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PasswordRecoverProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_reset, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Recuperar contraseña',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _correoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        keyboardType: TextInputType.emailAddress,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      if (prov.error != null)
                        Text(
                          _cleanError(prov.error!),
                          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          icon: prov.loading
                              ? const SizedBox(
                                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(
                            prov.loading ? 'Enviando...' : 'Enviar código',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: prov.loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  await prov.iniciar(_correoCtrl.text.trim());
                                  if (prov.correoEnProceso != null && prov.error == null) {
                                    if (mounted) {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordVerifyPage(),
                                      ));
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}