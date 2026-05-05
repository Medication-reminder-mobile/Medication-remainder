import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedReminderApp());
}

class MedReminderApp extends StatelessWidget {
  const MedReminderApp({super.key});

  static ThemeData _theme(Brightness brightness) {
    const surface = Color(0xFFF5F7F7);
    const darkSurface = Color(0xFF0E1D1E);
    const primary = Color(0xFF0A7776);
    const darkPrimary = Color(0xFF1AB9B0);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brightness == Brightness.dark ? darkPrimary : primary,
        brightness: brightness,
      ).copyWith(
        primary: brightness == Brightness.dark ? darkPrimary : primary,
        secondary: const Color(0xFF006B5A),
        surface: brightness == Brightness.dark ? darkSurface : surface,
      ),
      scaffoldBackgroundColor: brightness == Brightness.dark ? darkSurface : surface,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark ? darkSurface : surface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medication Reminder',
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: const _AppShellScreen(),
    );
  }
}

class _AppShellScreen extends StatelessWidget {
  const _AppShellScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
