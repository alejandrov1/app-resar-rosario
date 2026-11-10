import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lunes 9 de noviembre de 2026, 8:00: tocan los misterios Gozosos.
final DateTime lunes = DateTime(2026, 11, 9, 8);

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}

/// Pone [hijo] dentro de una MaterialApp con los proveedores que usan las pantallas.
Widget envolver(
  Widget hijo, {
  required PreferencesService preferencias,
  RosarioSession? sesion,
  NotificationService? notificaciones,
  ThemeData? tema,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PreferencesService>.value(value: preferencias),
      ChangeNotifierProvider<RosarioSession>.value(value: sesion ?? RosarioSession(reloj: () => lunes)),
      if (notificaciones != null) ChangeNotifierProvider<NotificationService>.value(value: notificaciones),
    ],
    child: MaterialApp(theme: tema ?? AppTheme.claro(), home: hijo),
  );
}
