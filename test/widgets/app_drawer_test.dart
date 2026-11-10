import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirMenu(WidgetTester tester) async {
    final preferencias = await preferenciasDePrueba();
    final clave = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(envolver(
      Scaffold(key: clave, drawer: const AppDrawer(), body: const SizedBox.shrink()),
      preferencias: preferencias,
    ));
    clave.currentState!.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('el menú muestra el misterio de hoy', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Misterios del día'), findsOneWidget);
    expect(find.text('Gozosos · Lunes'), findsOneWidget);
    expect(find.text('Agendar Rosario'), findsOneWidget);
  });

  testWidgets('abre el diálogo con los 5 misterios y se cierra', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();

    expect(find.text('Misterios Gozosos'), findsOneWidget);
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Misterios Gozosos'), findsNothing);
  });
}
