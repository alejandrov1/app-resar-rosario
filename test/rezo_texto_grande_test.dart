import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Reza los 93 pasos con la pantalla y los tamaños de texto indicados. Un desborde
  /// hace fallar la prueba; además el botón debe verse completo antes de cada toque.
  Future<void> recorrer(
    WidgetTester tester, {
    required Size pantalla,
    required double escalaApp,
    double escalaSistema = 1.0,
  }) async {
    tester.view.physicalSize = pantalla * 3;
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = escalaSistema;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': escalaApp}));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();

    final pantallaCompleta = Offset.zero & pantalla;
    for (var paso = 0; paso < 93; paso++) {
      expect(tester.takeException(), isNull, reason: 'paso $paso');
      final texto = paso == 92 ? 'Terminar Rosario' : 'Continuar';
      final boton = find.ancestor(of: find.text(texto), matching: find.byType(FilledButton));
      expect(boton, findsOneWidget, reason: 'paso $paso');
      final rect = tester.getRect(boton);
      final tarjeta = tester.getRect(find.byType(Card).first);
      expect(pantallaCompleta.contains(rect.topLeft) && pantallaCompleta.contains(rect.bottomRight), isTrue,
          reason: 'paso $paso: el botón $rect se sale de la pantalla $pantallaCompleta');
      expect(tarjeta.contains(rect.topLeft) && tarjeta.contains(rect.bottomRight), isTrue,
          reason: 'paso $paso: el botón $rect queda cortado por la tarjeta $tarjeta');
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  }

  testWidgets('en horizontal con el texto al 200 % se reza todo sin cortes', (tester) async {
    await recorrer(tester, pantalla: const Size(780, 360), escalaApp: 2.0);
  });

  testWidgets('en vertical con texto de la app al 200 % y del sistema al 150 % se reza todo sin cortes',
      (tester) async {
    await recorrer(tester, pantalla: const Size(360, 780), escalaApp: 2.0, escalaSistema: 1.5);
  });
}
