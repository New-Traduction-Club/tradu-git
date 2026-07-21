import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/l10n/app_localizations.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/src/workspace_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader(l10n.editor),
          SwitchListTile(
            value: settings.wordWrap,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accentSoft,
            inactiveThumbColor: AppTheme.muted,
            inactiveTrackColor: AppTheme.surface,
            tileColor: AppTheme.surface,
            title: Text(
              l10n.wordWrap,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l10n.wordWrapSubtitle,
              style: const TextStyle(
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
            title: Text(
              l10n.editorTheme,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              settings.theme == 'amoled' ? l10n.themeBlack : l10n.themeDefault,
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
            title: Text(
              l10n.simpleMode,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              l10n.simpleModeSubtitle,
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
              title: Text(
                l10n.editorTheme,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      l10n.themeDefault,
                      style: const TextStyle(color: AppTheme.ink),
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
                    title: Text(
                      l10n.themeBlack,
                      style: const TextStyle(color: AppTheme.ink),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          title: Text(
            l10n.enableSimpleModeTitle,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.simpleModeIntro,
                  style: const TextStyle(color: AppTheme.ink, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.simpleModeDetails,
                  style: const TextStyle(color: AppTheme.ink, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.simpleModeWarning,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
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
              child: Text(l10n.enable),
            ),
          ],
        );
      },
    );
  }
}
