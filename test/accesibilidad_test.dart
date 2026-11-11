import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> cumpleGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  Future<void> abrirDesdeMenu(WidgetTester tester, String opcion) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion));
    await tester.pumpAndSettle();
  }

  testWidgets('inicio, rezo, configuración y recordatorios cumplen tamaño táctil y etiquetas', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await cumpleGuias(tester);

    await abrirDesdeMenu(tester, 'Configuración');
    await cumpleGuias(tester);
    await tester.tap(find.byType(BackButton)); // pageBack busca el tooltip "Back" (en inglés)
    await tester.pumpAndSettle();

    await abrirDesdeMenu(tester, 'Agendar Rosario');
    await cumpleGuias(tester);
    await tester.tap(find.byType(BackButton)); // pageBack busca el tooltip "Back" (en inglés)
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    await cumpleGuias(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await cumpleGuias(tester); // paso de Ave María con cuentas
    handle.dispose();
  });

  testWidgets('con el texto al 200 % en un teléfono chico se recorre todo el rosario sin cortes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 × 780 dp
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': 2.0}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    for (var paso = 1; paso < 93; paso++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'paso $paso');
    }
    expect(find.text('Terminar Rosario'), findsOneWidget);
  });
}
