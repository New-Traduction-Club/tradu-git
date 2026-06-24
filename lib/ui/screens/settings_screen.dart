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
}
