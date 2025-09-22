import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stopfire_mobile/features/register/presentation/state/register_provider.dart';
import 'package:stopfire_mobile/features/register/presentation/pages/verify_otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _ci = TextEditingController();
  final _correo = TextEditingController();
  final _celular = TextEditingController();
  final _pass = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _ci.dispose();
    _correo.dispose();
    _celular.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rp = context.read<RegisterProvider>();
    final ok = await rp.start(
      nombre: _nombre.text.trim(),
      apellido: _apellido.text.trim(),
      ci: _ci.text.trim(),
      correo: _correo.text.trim(),
      celular: _celular.text.trim(),
      contrasena: _pass.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerifyOtpPage(correo: _correo.text.trim())),
      );
    } else if (rp.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rp.error!)));
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RegisterProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _apellido,
                decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ci,
                decoration: const InputDecoration(labelText: 'CI', border: OutlineInputBorder()),
                validator: _required,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
                validator: (v) {
                  if (_required(v) != null) return 'Requerido';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v!.trim())) return 'Correo inválido';
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _celular,
                decoration: const InputDecoration(labelText: 'Celular', border: OutlineInputBorder()),
                validator: _required,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                  ),
                ),
                obscureText: _obscure,
                validator: (v) {
                  if (_required(v) != null) return 'Requerido';
                  if (v!.length < 8) return 'La contraseña tiene que ser mínimo de 8 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: rp.loading ? null : _submit,
                  child: rp.loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continuar'),
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