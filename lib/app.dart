import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/screens/dashboard_screen.dart';
import 'package:tradu_git/ui/screens/onboarding_screen.dart';
import 'package:tradu_git/ui/screens/saf_setup_screen.dart';

class TraduGitApp extends StatelessWidget {
  const TraduGitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tradu-Git',
      theme: _buildDarkTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      routes: {
        '/': (_) => const OnboardingScreen(),
        '/saf': (_) => const SafSetupScreen(),
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
