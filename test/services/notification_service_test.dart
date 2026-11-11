import 'dart:convert';

import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../support/fake_notifications_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late tz.Location mx;
  late FakeNotificationsGateway gateway;
  late NotificationService servicio;

  tz.TZDateTime lunes6am() => tz.TZDateTime(mx, 2026, 11, 9, 6);

  RosarioReminder borrador({List<int> dias = const [1, 3], ReminderType tipo = ReminderType.notification}) {
    return RosarioReminder(
      id: 0,
      title: 'Rosario',
      description: 'Es hora de tu oración',
      time: const TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: dias,
      isActive: true,
      type: tipo,
      createdAt: DateTime(2026, 11, 1),
    );
  }

  Future<void> iniciar({Map<String, Object> guardado = const {}}) async {
    SharedPreferences.setMockInitialValues(guardado);
    servicio = NotificationService(gateway: gateway, now: lunes6am);
    await servicio.initialize();
  }

  setUpAll(() {
    tzdata.initializeTimeZones();
    mx = tz.getLocation('America/Mexico_City');
  });

  setUp(() => gateway = FakeNotificationsGateway());

  test('agregar asigna el ID 1, guarda y programa un aviso por día', () async {
    await iniciar();
    final resultado = await servicio.addReminder(borrador());

    expect(resultado.ok, isTrue);
    expect(servicio.reminders.single.id, 1);
    expect(gateway.scheduled.keys, unorderedEquals([11, 13]));
    expect(gateway.scheduled[11]!.date, tz.TZDateTime(mx, 2026, 11, 9, 7));
    expect(gateway.scheduled[13]!.date, tz.TZDateTime(mx, 2026, 11, 11, 7));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(NotificationService.storageKey), hasLength(1));
  });

  test('la alarma usa el canal de alarma', () async {
    await iniciar();
    await servicio.addReminder(borrador(tipo: ReminderType.alarm));
    expect(gateway.scheduled.values.every((a) => a.isAlarm), isTrue);
  });

  test('sin permiso de alarmas exactas programa en modo inexacto', () async {
    gateway.permissions = const NotificationPermissions(notifications: true, exactAlarms: false);
    await iniciar();
    await servicio.addReminder(borrador());
    expect(gateway.scheduled.values.every((a) => !a.exact), isTrue);
  });

  test('al conceder permisos se reprograma en modo exacto', () async {
    gateway
      ..permissions = const NotificationPermissions(notifications: true, exactAlarms: false)
      ..permissionsAfterRequest = const NotificationPermissions(notifications: true, exactAlarms: true);
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.requestPermissions();
    expect(servicio.permissions.exactAlarms, isTrue);
    expect(gateway.scheduled.values.every((a) => a.exact), isTrue);
  });

  test('editar cancela los 7 días anteriores y programa los nuevos', () async {
    await iniciar();
    await servicio.addReminder(borrador(dias: [1, 3]));
    await servicio.updateReminder(servicio.reminders.single.copyWith(daysOfWeek: [5]));
    expect(gateway.cancelled, containsAll([11, 12, 13, 14, 15, 16, 17]));
    expect(gateway.scheduled.keys, [15]);
  });

  test('desactivar cancela sin volver a programar', () async {
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.toggleReminder(1);
    expect(servicio.reminders.single.isActive, isFalse);
    expect(gateway.scheduled, isEmpty);
  });

  test('eliminar cancela y borra', () async {
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.removeReminder(1);
    expect(servicio.reminders, isEmpty);
    expect(gateway.scheduled, isEmpty);
  });

  test('si no se puede programar lo dice, pero conserva el recordatorio', () async {
    await iniciar();
    gateway.failSchedule = true;
    final resultado = await servicio.addReminder(borrador());
    expect(resultado.ok, isFalse);
    expect(resultado.message, contains('no se pudo programar'));
    expect(servicio.reminders, hasLength(1));
  });

  test('al iniciar migra IDs antiguos y el tipo "ambos", y descarta registros dañados', () async {
    Map<String, Object> registro(int id, int tipo) => {
          'id': id,
          'title': 'R$id',
          'description': 'd',
          'hour': 7,
          'minute': 0,
          'daysOfWeek': [1],
          'isActive': true,
          'type': tipo,
          'createdAt': '2026-11-01T00:00:00.000',
        };
    await iniciar(guardado: {
      NotificationService.storageKey: [
        jsonEncode(registro(1500000, 2)),
        'esto-no-es-json',
        jsonEncode(registro(2000000, 0)),
      ],
    });

    expect(servicio.reminders.map((r) => r.id), [1, 2]);
    expect(servicio.reminders.first.type, ReminderType.alarm);
    expect(gateway.cancelAllCalls, 1);
    expect(gateway.scheduled.keys, unorderedEquals([11, 21]));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(NotificationService.storageKey), hasLength(2));
  });

  test('si el plugin no inicia, queda no disponible con un mensaje', () async {
    gateway.failInitialize = true;
    await iniciar();
    expect(servicio.isAvailable, isFalse);
    expect(servicio.initError, isNotNull);
  });

  test('pedir alarmas exactas vuelve a revisar los permisos', () async {
    await iniciar();
    await servicio.requestExactAlarms();
    expect(gateway.requestExactAlarmsCalls, 1);
  });
}
