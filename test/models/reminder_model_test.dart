import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RosarioReminder ejemplo({int id = 1, String title = 'Rosario', ReminderType type = ReminderType.notification}) {
  return RosarioReminder(
    id: id,
    title: title,
    description: 'Es hora',
    time: const TimeOfDay(hour: 7, minute: 30),
    daysOfWeek: const [1, 3, 5],
    isActive: true,
    type: type,
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  test('se guarda y se lee igual', () {
    final r = ejemplo(type: ReminderType.alarm);
    expect(RosarioReminder.fromMap(r.toMap()).toMap(), r.toMap());
  });

  test('el antiguo tipo "Notificación y Alarma" se lee como Alarma', () {
    final mapa = ejemplo().toMap()..['type'] = 2;
    expect(RosarioReminder.fromMap(mapa).type, ReminderType.alarm);
  });

  test('un tipo desconocido se lee como Notificación', () {
    final mapa = ejemplo().toMap()..['type'] = 99;
    expect(RosarioReminder.fromMap(mapa).type, ReminderType.notification);
  });

  test('rechaza días inválidos', () {
    final mapa = ejemplo().toMap()..['daysOfWeek'] = [0, 8];
    expect(() => RosarioReminder.fromMap(mapa), throwsFormatException);
  });

  test('textos legibles', () {
    expect(ejemplo().timeText, '07:30');
    expect(ejemplo().daysText, 'Lun, Mié, Vie');
    expect(ejemplo().copyWith(daysOfWeek: [1, 2, 3, 4, 5, 6, 7]).daysText, 'Todos los días');
  });

  group('renumberIfNeeded', () {
    test('no cambia nada si los IDs ya son válidos', () {
      expect(renumberIfNeeded([ejemplo(id: 1), ejemplo(id: 2)]), isNull);
    });

    test('renumera los IDs antiguos y conserva lo demás', () {
      final resultado = renumberIfNeeded([ejemplo(id: 1500000, title: 'A'), ejemplo(id: 2000000, title: 'B')])!;
      expect(resultado.map((r) => r.id), [1, 2]);
      expect(resultado.map((r) => r.title), ['A', 'B']);
    });

    test('renumera si hay IDs repetidos', () {
      expect(renumberIfNeeded([ejemplo(id: 3), ejemplo(id: 3)])!.map((r) => r.id), [1, 2]);
    });
  });

  test('las plantillas rápidas son válidas', () {
    expect(ReminderTemplates.templates, hasLength(4));
    for (final plantilla in ReminderTemplates.templates) {
      expect(plantilla.daysOfWeek, isNotEmpty);
      expect(plantilla.daysOfWeek.every((d) => d >= 1 && d <= 7), isTrue);
    }
  });
}
