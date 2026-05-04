import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedReminderApp());
}

/// Root widget: Material 3 theme + named routes for team integration.
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
      title: 'Vitalis Medication Manager',
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
