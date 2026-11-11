import 'package:app_resar_rosario/app.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'fake_notifications_gateway.dart';

/// Lunes 9 de noviembre de 2026, 8:00: tocan los misterios Gozosos.
final DateTime lunes = DateTime(2026, 11, 9, 8);

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}

/// Servicio de recordatorios con el doble del sistema. Usa las preferencias simuladas que ya estén puestas.
Future<NotificationService> notificacionesDePrueba(
  FakeNotificationsGateway gateway, {
  tz.TZDateTime Function()? ahora,
}) async {
  final servicio = NotificationService(
    gateway: gateway,
    now: ahora ?? () => tz.TZDateTime(tz.UTC, 2026, 11, 9, 6),
  );
  await servicio.initialize();
  return servicio;
}

/// Todo lo que necesita la app completa, con dobles.
Future<({PreferencesService preferencias, NotificationService notificaciones, FakeNotificationsGateway gateway})>
    dependenciasDePrueba({Map<String, Object> preferencias = const {}}) async {
  final prefs = await preferenciasDePrueba(preferencias);
  final gateway = FakeNotificationsGateway();
  return (preferencias: prefs, notificaciones: await notificacionesDePrueba(gateway), gateway: gateway);
}

/// La app completa, lista para `pumpWidget`.
Future<Widget> appDePrueba({Map<String, Object> preferencias = const {}}) async {
  final d = await dependenciasDePrueba(preferencias: preferencias);
  return SantoRosarioApp(preferencias: d.preferencias, notificaciones: d.notificaciones, reloj: () => lunes);
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
