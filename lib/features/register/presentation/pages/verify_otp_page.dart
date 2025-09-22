import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/register/presentation/state/register_provider.dart';
import 'package:stopfire_mobile/features/auth/presentation/pages/login_page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String correo;
  const VerifyOtpPage({super.key, required this.correo});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rp = context.read<RegisterProvider>();
    final ok = await rp.verify(correo: widget.correo, codigo: _codeCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta verificada. Ahora puedes iniciar sesión.')));
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
    } else if (rp.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rp.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RegisterProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.correo,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código OTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el código' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: rp.loading ? null : _submit,
                  child: rp.loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verificar'),
                ),
              ),
              if (rp.error != null) ...[
                const SizedBox(height: 8),
                Text(rp.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}