import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resar_rosario_app.dart';
import 'services/preferences_service.dart';
import 'constants/app_theme.dart';

void main() {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientaciones soportadas
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Configurar el estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PreferencesService _preferences = PreferencesService();

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en las preferencias
    _preferences.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    _preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    setState(() {
      // Reconstruir la app cuando cambien las preferencias
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santo Rosario',
      theme: AppTheme.lightTheme(_preferences.textScaleFactor),
      darkTheme: AppTheme.darkTheme(_preferences.textScaleFactor),
      themeMode: _preferences.themeMode,
      home: RosarioApp(preferences: _preferences),
      debugShowCheckedModeBanner: false,
      
      // Configuración de accesibilidad
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            highContrast: _preferences.useHighContrast, textScaler: TextScaler.linear(_preferences.textScaleFactor),
          ),
          child: child!,
        );
      },
    );
  }
}