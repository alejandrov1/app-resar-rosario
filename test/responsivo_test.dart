import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/app_harness.dart';
import 'support/recorridos_app.dart';

const _tamanos = <String, Size>{
  'teléfono 360×640': Size(360, 640),
  'teléfono 411×914': Size(411, 914),
  'horizontal 640×360': Size(640, 360),
  'tableta 800×1280': Size(800, 1280),
};

/// Escala de la app × escala del sistema. 300 % es el máximo que permite la app.
const _escalas = <String, (double, double)>{
  'texto 100 %': (1.0, 1.0),
  'texto 200 %': (2.0, 1.0),
  'texto 300 %': (2.0, 1.5),
};

/// Todo botón visible escribe su etiqueta en una sola línea: ninguna palabra se parte.
void _etiquetasEnUnaLinea(WidgetTester tester, String pantalla) {
  for (final boton in find.byWidgetPredicate((w) => w is ButtonStyleButton).evaluate()) {
    // Los botones de los diálogos de Flutter no se pueden reducir: se limita su escala (ver el test de "Acerca de").
    var deFlutter = false;
    boton.visitAncestorElements((e) => !(deFlutter = e.widget is AboutDialog));
    if (deFlutter) continue;
    final parrafos = find.descendant(of: find.byElementPredicate((e) => e == boton), matching: find.byType(RichText));
    for (final parrafo in parrafos.evaluate().map((e) => e.renderObject).whereType<RenderParagraph>()) {
      if (parrafo.text.style?.fontFamily == 'MaterialIcons') continue; // el glifo de un icono no es texto
      final cajas = parrafo.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: parrafo.text.toPlainText().length),
      );
      expect(cajas.map((c) => c.top.round()).toSet(), hasLength(1),
          reason: '$pantalla: la etiqueta "${parrafo.text.toPlainText()}" se parte en varias líneas');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final MapEntry(key: nombreTamano, value: tamano) in _tamanos.entries) {
    for (final MapEntry(key: nombreEscala, value: (escalaApp, escalaSistema)) in _escalas.entries) {
      for (final recorrido in recorridos) {
        testWidgets('$nombreTamano · $nombreEscala · ${recorrido.nombre}', (tester) async {
          tester.view.physicalSize = tamano * 3;
          tester.view.devicePixelRatio = 3.0;
          tester.view.padding = const FakeViewPadding(top: 72, bottom: 144); // barra de estado 24 dp, navegación 48 dp
          tester.platformDispatcher.textScaleFactorTestValue = escalaSistema;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final revisarGuias = escalaApp == 1.0 && escalaSistema == 1.0;
          final semantica = revisarGuias ? tester.ensureSemantics() : null;
          // Se libera aunque falle una comprobación: flutter_test verifica los manejadores antes de los addTearDown,
          // y un manejador pendiente taparía la causa real.
          try {
            await tester.pumpWidget(
              await appDePrueba(preferencias: {'pref_text_scale': escalaApp}, gateway: recorrido.gateway?.call()),
            );
            await tester.pumpAndSettle();
            final areaUtil = Rect.fromLTRB(0, 24, tamano.width, tamano.height - 48);

            await recorrido.recorrer(tester, (pantalla) async {
              expect(tester.takeException(), isNull, reason: pantalla);
              _etiquetasEnUnaLinea(tester, pantalla);
              for (final texto in ['Continuar', 'Terminar Rosario', 'Guardar']) {
                final boton = find.ancestor(of: find.text(texto), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
                if (boton.evaluate().isEmpty) continue;
                final rect = tester.getRect(boton.first);
                expect(areaUtil.contains(rect.topLeft) && areaUtil.contains(rect.bottomRight), isTrue,
                    reason: '$pantalla: "$texto" $rect se sale de $areaUtil');
              }
              if (revisarGuias) {
                await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: pantalla);
                await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: pantalla);
              }
            });
            expect(tester.takeException(), isNull);
          } finally {
            semantica?.dispose();
          }
        });
      }
    }
  }

  group('ancho máximo y áreas seguras en las listas', () {
    Future<void> abrir(WidgetTester tester, Size tamano, String opcion) async {
      tester.view.physicalSize = tamano * 3;
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await appDePrueba());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tocar(tester, find.text(opcion));
    }

    testWidgets('Configuración mide como máximo 600 dp en tableta', (tester) async {
      await abrir(tester, const Size(800, 1280), 'Configuración');
      expect(tester.getSize(find.widgetWithText(ListTile, 'Tamaño del texto')).width, lessThanOrEqualTo(600));
      expect(tester.getSize(find.byType(Slider)).width, lessThanOrEqualTo(600));
    });

    testWidgets('Mis recordatorios mide como máximo 600 dp en tableta', (tester) async {
      await abrir(tester, const Size(800, 1280), 'Agendar Rosario');
      await tocar(tester, find.text('Nuevo'));
      await tocar(tester, find.byTooltip('Lunes'));
      await tocar(tester, find.text('Guardar'));
      expect(tester.getSize(find.byType(Card).first).width, lessThanOrEqualTo(600));
      expect(tester.getSize(find.widgetWithText(Card, 'Rezar el Santo Rosario')).width, lessThanOrEqualTo(600));
    });

    testWidgets('Configuración deja su último elemento sobre la barra de navegación', (tester) async {
      await abrir(tester, const Size(360, 640), 'Configuración');
      await tester.dragUntilVisible(
        find.text('Restablecer configuración'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.widgetWithText(ListTile, 'Restablecer configuración')).bottom, lessThanOrEqualTo(640 - 48));
    });

    testWidgets('Mis recordatorios deja su último elemento sobre la barra de navegación', (tester) async {
      await abrir(tester, const Size(360, 640), 'Agendar Rosario');
      await tocar(tester, find.text('Nuevo'));
      await tocar(tester, find.byTooltip('Lunes'));
      await tocar(tester, find.text('Guardar'));
      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.widgetWithText(Card, 'Rezar el Santo Rosario')).bottom, lessThanOrEqualTo(640 - 48));
    });
  });
}
