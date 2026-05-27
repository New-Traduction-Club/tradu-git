import 'package:flutter/material.dart';
import 'package:tradu_git/ui/app_theme.dart';

class SafSetupScreen extends StatelessWidget {
  const SafSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccion de carpeta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona la carpeta donde se guardaran tus repositorios.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.ink,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carpeta actual',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.muted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin seleccionar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.ink,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.folder_open),
                label: const Text('Seleccionar carpeta'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/dashboard');
                },
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
