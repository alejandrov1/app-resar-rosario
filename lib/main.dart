import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resar_rosario_app.dart';
import 'services/preferences_service.dart';
import 'constants/app_theme.dart';
import 'widgets/settings_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    _preferences.addListener(_onPreferencesChanged);
  }

  @override
  void dispose() {
    _preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  void _onPreferencesChanged() {
    setState(() {});
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