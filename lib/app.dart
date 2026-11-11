import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'logic/rosario_session.dart';
import 'screens/principal_screen.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

/// Raíz de la app: proveedores, temas, idioma y escalado de texto.
class SantoRosarioApp extends StatelessWidget {
  const SantoRosarioApp({super.key, required this.preferencias, required this.notificaciones, this.reloj});

  final PreferencesService preferencias;
  final NotificationService notificaciones;

  /// Reloj para pruebas; en la app es `DateTime.now`.
  final DateTime Function()? reloj;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(value: preferencias),
        ChangeNotifierProvider<NotificationService>.value(value: notificaciones),
        ChangeNotifierProvider<RosarioSession>(create: (_) => RosarioSession(reloj: reloj)),
      ],
      child: Consumer<PreferencesService>(
        builder: (context, prefs, _) => MaterialApp(
          title: 'Santo Rosario',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(altoContraste: prefs.useHighContrast, botonesGrandes: prefs.useLargeButtons),
          darkTheme: AppTheme.oscuro(altoContraste: prefs.useHighContrast, botonesGrandes: prefs.useLargeButtons),
          themeMode: prefs.themeMode,
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            // El tamaño elegido en la app se suma al del sistema, una sola vez.
            final sistema = MediaQuery.textScalerOf(context).scale(16) / 16;
            final escala = (sistema * prefs.textScaleFactor).clamp(0.8, 3.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            );
          },
          home: const PrincipalScreen(),
        ),
      ),
    );
  }
}
