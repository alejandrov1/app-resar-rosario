import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'resar_rosario_app.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'constants/app_theme.dart';
import 'widgets/settings_drawer.dart';

void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // ¡CRÍTICO! Inicializar el servicio de notificaciones ANTES de correr la app
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Método de utilidad para limpiar recordatorios con IDs inválidos de versiones anteriores
  await notificationService.cleanInvalidReminders();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PreferencesService()),
        // Proveer la instancia ya inicializada del servicio
        ChangeNotifierProvider.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PreferencesService _preferences;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preferences = context.watch<PreferencesService>();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santo Rosario',
      theme: AppTheme.lightTheme(_preferences.textScaleFactor),
      darkTheme: AppTheme.darkTheme(_preferences.textScaleFactor),
      themeMode: _preferences.themeMode,
      home: MainScreen(preferences: _preferences),
      debugShowCheckedModeBanner: false,
      
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_preferences.textScaleFactor),
            highContrast: _preferences.useHighContrast,
          ),
          child: child!,
        );
      },
    );
  }
}

class MainScreen extends StatelessWidget {
  final PreferencesService preferences;

  const MainScreen({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SettingsDrawer(preferences: preferences),
      body: RosarioApp(preferences: preferences),
    );
  }
}