import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/src/workspace_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('Editor'),
          SwitchListTile(
            value: settings.wordWrap,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accentSoft,
            inactiveThumbColor: AppTheme.muted,
            inactiveTrackColor: AppTheme.surface,
            tileColor: AppTheme.surface,
            title: const Text(
              'Ajuste de línea',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Ajustar líneas para que quepan en la pantalla sin movimiento horizontal.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
              ),
            ),
            onChanged: (bool value) {
              ref.read(appSettingsProvider.notifier).updateWordWrap(value);
            },
          ),
          ListTile(
            tileColor: AppTheme.surface,
            title: const Text(
              'Tema del Editor',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              settings.theme == 'amoled' ? 'Negro' : 'Por defecto',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.muted,
            ),
            onTap: () => _showThemeSelectorDialog(context, ref),
          ),
          SwitchListTile(
            value: settings.simpleMode,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accentSoft,
            inactiveThumbColor: AppTheme.muted,
            inactiveTrackColor: AppTheme.surface,
            tileColor: AppTheme.surface,
            title: const Text(
              'Modo Simple',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'Sincronización automática de Git al abrir y guardar archivos.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
              ),
            ),
            onChanged: (bool value) {
              if (value) {
                _showSimpleModeCautionDialog(context, ref);
              } else {
                ref.read(appSettingsProvider.notifier).updateSimpleMode(false);
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  void _showThemeSelectorDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final currentTheme = ref.watch(appSettingsProvider).theme;
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.border, width: 1),
              ),
              title: const Text(
                'Tema del Editor',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Por defecto',
                      style: TextStyle(color: AppTheme.ink),
                    ),
                    value: 'darcula',
                    groupValue: currentTheme,
                    activeColor: AppTheme.accent,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(appSettingsProvider.notifier).updateTheme(val);
                        Navigator.pop(dialogContext);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Negro',
                      style: TextStyle(color: AppTheme.ink),
                    ),
                    value: 'amoled',
                    groupValue: currentTheme,
                    activeColor: AppTheme.accent,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(appSettingsProvider.notifier).updateTheme(val);
                        Navigator.pop(dialogContext);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSimpleModeCautionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          title: const Text(
            'Activar Modo Simple',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'El Modo Simple automatiza las operaciones de Git para facilitar la sincronización:',
                  style: TextStyle(color: AppTheme.ink, fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  '• Al abrir un repositorio, se realizarán automáticamente las operaciones de búsqueda y obtención de cambios.\n'
                  '• Al guardar cualquier archivo se creará un commit automático y se enviarán los cambios.',
                  style: TextStyle(color: AppTheme.ink, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  '• Si hay cambios conflictivos en el repositorio remoto, las operaciones automáticas podrían fallar y requerir interacción humana..',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                ref.read(appSettingsProvider.notifier).updateSimpleMode(true);
                Navigator.pop(context);
              },
              child: const Text('Activar'),
            ),
          ],
        );
      },
    );
  }
}
