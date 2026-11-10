import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'resar_rosario_app.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'widgets/settings_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferencias = PreferencesService(await SharedPreferences.getInstance());
  final notificaciones = NotificationService();
  try {
    await notificaciones.initialize();
    if (notificaciones.isInitialized) {
      await notificaciones.cleanInvalidReminders();
    }
  } catch (e) {
    debugPrint('Error al inicializar las notificaciones: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferencias),
        ChangeNotifierProvider.value(value: notificaciones),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferencesService>();
    return MaterialApp(
      title: 'Santo Rosario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(
        altoContraste: preferencias.useHighContrast,
        botonesGrandes: preferencias.useLargeButtons,
      ),
      darkTheme: AppTheme.oscuro(
        altoContraste: preferencias.useHighContrast,
        botonesGrandes: preferencias.useLargeButtons,
      ),
      themeMode: preferencias.themeMode,
      home: MainScreen(preferences: preferencias),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(preferencias.textScaleFactor),
        ),
        child: child!,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.preferences});

  final PreferencesService preferences;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SettingsDrawer(preferences: preferences),
      body: RosarioApp(preferences: preferences),
    );
  }
}
