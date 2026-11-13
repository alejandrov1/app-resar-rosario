import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/screens/recordatorio_form_screen.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Abre el formulario desde una pantalla vacía y guarda lo que devuelve al cerrarse.
  Future<List<RosarioReminder?>> abrir(WidgetTester tester, {RosarioReminder? recordatorio}) async {
    final resultados = <RosarioReminder?>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  resultados.add(await RecordatorioFormScreen.abrir(context, recordatorio: recordatorio)),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return resultados;
  }

  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
    await tester.tap(objetivo);
    await tester.pumpAndSettle();
  }

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

  testWidgets('sin días no guarda y lo indica', (tester) async {
    final resultados = await abrir(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un día'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('sin título no guarda y lo indica', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un título'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('guarda con los días y el tipo elegidos', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tocar(tester, find.text('X'));
    await tocar(tester, find.text('Alarma'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect(r.title, 'Rezar el Santo Rosario');
    expect(r.daysOfWeek, [1, 3]);
    expect(r.type, ReminderType.alarm);
    expect(r.time, const TimeOfDay(hour: 19, minute: 0));
    expect(r.isActive, isTrue);
  });

  testWidgets('el atajo Entre semana marca de lunes a viernes', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('Entre semana'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(resultados.single!.daysOfWeek, [1, 2, 3, 4, 5]);
  });

  testWidgets('una plantilla llena el formulario', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('Rosario Matutino'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect(r.title, 'Rosario Matutino');
    expect(r.description, 'Momento perfecto para comenzar el día con oración');
    expect(r.time, const TimeOfDay(hour: 7, minute: 0));
    expect(r.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(r.type, ReminderType.notification);
  });

  testWidgets('al editar conserva el ID y los datos, y no muestra plantillas', (tester) async {
    final resultados = await abrir(tester, recordatorio: existente);
    expect(find.text('Editar recordatorio'), findsOneWidget);
    expect(find.text('Plantillas'), findsNothing);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect([r.id, r.title, r.daysOfWeek, r.isActive], [5, 'Mañana', [2], false]);
  });

  testWidgets('cerrar sin cambios no pregunta', (tester) async {
    final resultados = await abrir(tester);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
    expect(resultados, [null]);
  });

  testWidgets('cerrar con cambios pregunta antes de descartar', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);

    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo recordatorio'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(resultados, [null]);
  });

  testWidgets('la hora se anuncia y se puede tocar para cambiarla', (tester) async {
    final handle = tester.ensureSemantics();
    await abrir(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Hora: .+\. Toca para cambiarla$')), findsOneWidget);
    await tocar(tester, find.text('Toca para cambiarla'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    handle.dispose();
  });
}
