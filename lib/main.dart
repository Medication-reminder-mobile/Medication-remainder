import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_keys.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/caregiver_provider.dart';
import 'providers/intake_log_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/rbc_provider.dart';
import 'providers/theme_provider.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/workmanager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService.instance.initialize();
  }
  await VoiceService.instance.initialize();
  if (!kIsWeb) {
    await WorkManagerService.instance.initialize();
    await WorkManagerService.instance.registerPeriodicTask();
  }
  runApp(const MedRemindApp());
}

class MedRemindApp extends StatelessWidget {
  const MedRemindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => IntakeLogProvider()),
        ChangeNotifierProvider(create: (_) => CaregiverProvider()),
        ChangeNotifierProvider(create: (_) => RbcProvider()),
        ProxyProvider<AuthProvider, GoRouter>(
          update: (context, auth, previous) => previous ?? createRouter(auth),
        ),
      ],
      child: Consumer3<ThemeProvider, LocaleProvider, GoRouter>(
        builder: (context, theme, locale, router, _) {
          return MaterialApp.router(
            title: 'MedRemind',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: AppKeys.messengerKey,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.themeMode,
            locale: locale.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('am'),
              Locale('ar'),
              Locale('fr'),
              Locale('es'),
              Locale('pt'),
              Locale('sw'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: router,
          );
        },
      ),
    );
  }
}
