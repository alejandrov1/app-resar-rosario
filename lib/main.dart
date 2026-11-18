import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/notifications_gateway.dart';
import 'services/preferences_service.dart';
import 'services/zona_horaria.dart';
import 'theme/barras_sistema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app dibuja hasta el borde (Android 15 ya lo hace): las barras del sistema son transparentes.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(estiloBarras(Brightness.dark));
  LicenseRegistry.addLicense(() async* {
    final licencia = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Lora'], licencia);
  });
  await configurarZonaHoraria();

  final preferencias = PreferencesService(await SharedPreferences.getInstance());
  final notificaciones = NotificationService(gateway: FlutterNotificationsGateway());
  await notificaciones.initialize(); // nunca lanza: si algo falla queda "no disponible"

  runApp(SantoRosarioApp(preferencias: preferencias, notificaciones: notificaciones));
}
