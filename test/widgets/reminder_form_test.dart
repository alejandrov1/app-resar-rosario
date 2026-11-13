import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/widgets/reminder_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<RosarioReminder>> mostrar(WidgetTester tester, {RosarioReminder? recordatorio}) async {
    final guardados = <RosarioReminder>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(body: ReminderForm(reminder: recordatorio, onSave: guardados.add)),
    ));
    return guardados;
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
  }

  testWidgets('sin días no guarda y lo indica', (tester) async {
    final guardados = await mostrar(tester);
    await guardar(tester);
    expect(find.text('Elige al menos un día'), findsOneWidget);
    expect(guardados, isEmpty);
  });

  testWidgets('sin título no guarda y lo indica', (tester) async {
    final guardados = await mostrar(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('L'));
    await guardar(tester);
    expect(find.text('Escribe un título'), findsOneWidget);
    expect(guardados, isEmpty);
  });

  testWidgets('guarda con los días y el tipo elegidos', (tester) async {
    final guardados = await mostrar(tester);
    await tester.tap(find.text('L'));
    await tester.tap(find.text('X'));
    await tester.tap(find.text('Alarma'));
    await guardar(tester);

    final r = guardados.single;
    expect(r.title, 'Rezar el Santo Rosario');
    expect(r.daysOfWeek, [1, 3]);
    expect(r.type, ReminderType.alarm);
    expect(r.time, const TimeOfDay(hour: 19, minute: 0));
    expect(r.isActive, isTrue);
  });

  testWidgets('al editar conserva el ID y los datos', (tester) async {
    final existente = RosarioReminder(
      id: 5,
      title: 'Mañana',
      description: 'd',
      time: const TimeOfDay(hour: 6, minute: 15),
      daysOfWeek: const [2],
      isActive: false,
      type: ReminderType.notification,
      createdAt: DateTime(2026, 1, 1),
    );
    final guardados = await mostrar(tester, recordatorio: existente);
    expect(find.text('Editar recordatorio'), findsOneWidget);
    await guardar(tester);

    final r = guardados.single;
    expect([r.id, r.title, r.daysOfWeek, r.isActive], [5, 'Mañana', [2], false]);
  });

  testWidgets('una plantilla llena el formulario', (tester) async {
    final guardados = await mostrar(tester);
    await tester.tap(find.text('Rosario Matutino'));
    await tester.pump();
    await guardar(tester);

    final r = guardados.single;
    expect(r.title, 'Rosario Matutino');
    expect(r.description, 'Momento perfecto para comenzar el día con oración');
    expect(r.time, const TimeOfDay(hour: 7, minute: 0));
    expect(r.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(r.type, ReminderType.notification);
  });

  testWidgets('al editar no se muestran plantillas', (tester) async {
    await mostrar(
      tester,
      recordatorio: RosarioReminder(
        id: 1,
        title: 'Noche',
        description: 'd',
        time: const TimeOfDay(hour: 21, minute: 0),
        daysOfWeek: const [7],
        isActive: true,
        type: ReminderType.alarm,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    expect(find.text('Plantillas rápidas'), findsNothing);
  });
}
