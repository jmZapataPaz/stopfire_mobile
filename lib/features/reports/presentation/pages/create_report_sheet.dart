import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:stopfire_mobile/features/auth/presentation/state/auth_provider.dart';
import 'package:stopfire_mobile/features/reports/presentation/state/report_provider.dart';

class CreateReportSheet extends StatelessWidget {
  const CreateReportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final auth = context.read<AuthProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.report, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text('Nuevo reporte', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PhotoBox(file: provider.photo, onTap: () => provider.takePhoto()),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => provider.descripcionSetter = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.error != null)
              Text(provider.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.sending
                    ? null
                    : () async {
                        try {
                          await provider.submit(token: auth.token!);
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (_) {
                        }
                      },
                icon: provider.sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: const Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;
  const _PhotoBox({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = 120.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.03),
        ),
        child: file == null
            ? const Center(child: Icon(Icons.camera_alt, size: 40))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}