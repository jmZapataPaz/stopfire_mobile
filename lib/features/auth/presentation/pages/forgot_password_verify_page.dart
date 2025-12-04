import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/state/password_recover_provider.dart';

class ForgotPasswordVerifyPage extends StatefulWidget {
  const ForgotPasswordVerifyPage({super.key});

  @override
  State<ForgotPasswordVerifyPage> createState() => _ForgotPasswordVerifyPageState();
}

class _ForgotPasswordVerifyPageState extends State<ForgotPasswordVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _showPass = false;
  bool _showPass2 = false;

  String _cleanError(String raw) {
    final s = raw.trim();
    final prefixMatch = RegExp(r'^HTTP\s+\d{3}:\s*').firstMatch(s);
    final noPrefix = prefixMatch != null ? s.substring(prefixMatch.end).trim() : s;

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

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PasswordRecoverProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar código')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                          Icon(Icons.verified, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Verificar código',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correo: ${prov.correoEnProceso ?? ""}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _codigoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          helperText: 'Ingresa el código recibido por correo',
                          prefixIcon: Icon(Icons.pin),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          // Solo dígitos
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 6, // ajusta al largo de tu OTP
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _showPass = !_showPass),
                            icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                            tooltip: _showPass ? 'Ocultar' : 'Mostrar',
                          ),
                        ),
                        obscureText: !_showPass,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass2Ctrl,
                        decoration: InputDecoration(
                          labelText: 'Repetir contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _showPass2 = !_showPass2),
                            icon: Icon(_showPass2 ? Icons.visibility_off : Icons.visibility),
                            tooltip: _showPass2 ? 'Ocultar' : 'Mostrar',
                          ),
                        ),
                        obscureText: !_showPass2,
                        validator: (v) => v != _passCtrl.text ? 'No coincide' : null,
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
                              : const Icon(Icons.check_circle),
                          label: Text(
                            prov.loading ? 'Actualizando...' : 'Actualizar contraseña',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          onPressed: prov.loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  final ok = await prov.verificar(
                                    _codigoCtrl.text.trim(),
                                    _passCtrl.text.trim(),
                                  );
                                  if (ok && mounted) {
                                    Navigator.of(context).popUntil((r) => r.isFirst);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Contraseña actualizada. Inicia sesión.')),
                                    );
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