import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/notifications_gateway.dart';
import 'services/preferences_service.dart';
import 'services/zona_horaria.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
