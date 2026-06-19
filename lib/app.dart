import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/screens/dashboard_screen.dart';
import 'package:tradu_git/ui/screens/onboarding_screen.dart';
import 'package:tradu_git/src/workspace_provider.dart';
import 'package:tradu_git/src/rust/api/simple.dart';

class TraduGitApp extends ConsumerStatefulWidget {
  const TraduGitApp({super.key});

  @override
  ConsumerState<TraduGitApp> createState() => _TraduGitAppState();
}

class _TraduGitAppState extends ConsumerState<TraduGitApp> {
  static const _storageChannel = MethodChannel('com.tdclub.tradu_git/storage');

  @override
  void initState() {
    super.initState();
    _loadInternalPath();
  }

  Future<void> _loadInternalPath() async {
    try {
      final String path = await _storageChannel.invokeMethod('getInternalStoragePath');
      
      // Dynamic SSL CA bundling setup for git2 (OpenSSL) on Android
      await setupSslCertificates(filesDir: path);

      final reposDir = Directory('$path/repos');
      if (!reposDir.existsSync()) {
        reposDir.createSync(recursive: true);
      }
      ref.read(internalReposPathProvider.notifier).setPath(reposDir.path);

      // Scan for existing drafts at startup to populate dirtyFilesProvider
      final draftsDir = Directory('$path/drafts');
      if (draftsDir.existsSync()) {
        try {
          final files = draftsDir.listSync();
          for (var file in files) {
            if (file is File && file.path.endsWith('.draft')) {
              final name = file.path.split('/').last.replaceAll('.draft', '');
              try {
                final decodedPath = Uri.decodeComponent(name);
                ref.read(dirtyFilesProvider.notifier).setDirty(decodedPath, true);
              } catch (e) {
                debugPrint('Error decoding draft filename: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('Error scanning drafts: $e');
        }
      }
    } catch (e) {
      debugPrint('Error getting internal storage path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tradu-Git',
      theme: _buildDarkTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routes: {
        '/': (_) => const OnboardingScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}

ThemeData _buildDarkTheme() {
  final baseTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppTheme.background,
    colorScheme: const ColorScheme.dark(
      primary: AppTheme.accent,
      surface: AppTheme.surface,
      background: AppTheme.background,
      outline: AppTheme.border,
    ),
    useMaterial3: true,
  );

  final textTheme = GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme).apply(
    bodyColor: AppTheme.ink,
    displayColor: AppTheme.ink,
  );

  return baseTheme.copyWith(
    textTheme: textTheme,
    visualDensity: VisualDensity.compact,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTheme.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    scrollbarTheme: const ScrollbarThemeData(
      radius: Radius.zero,
      thickness: MaterialStatePropertyAll(6),
      thumbColor: MaterialStatePropertyAll(AppTheme.border),
      trackColor: MaterialStatePropertyAll(Colors.transparent),
    ),
    cardTheme: const CardThemeData(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppTheme.accent, width: 1.2),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppTheme.border,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: AppTheme.border),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppTheme.surface,
      height: 58,
      labelTextStyle: MaterialStatePropertyAll(TextStyle(fontSize: 11)),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),
  );
}
