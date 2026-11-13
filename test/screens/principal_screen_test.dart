import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/screens/principal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inicio muestra el día y el misterio, y empieza a rezar', (tester) async {
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('Misterios Gozosos'), findsOneWidget);

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    expect(find.text('Oraciones iniciales · 1 de 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });

  testWidgets('la tarjeta del día abre los 5 misterios', (tester) async {
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver los 5 misterios'));
    await tester.tap(find.text('Ver los 5 misterios'));
    await tester.pumpAndSettle();
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('La Encarnación del Hijo de Dios'), findsNothing);
  });

  testWidgets('la tarjeta del día se activa con el lector de pantalla', (tester) async {
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver los 5 misterios'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('Ver los 5 misterios')));
    await tester.pumpAndSettle();
    expect(find.text('Entendido'), findsOneWidget);
    semantica.dispose();
  });

  for (final escala in [1.0, 1.5]) {
    testWidgets('en 360×640 con texto al ${(escala * 100).round()} % "Comenzar a Rezar" se ve sin desplazar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144); // barras de estado y de navegación
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': escala}));
      await tester.pumpAndSettle();
      final boton = tester.getRect(find.ancestor(of: find.text('Comenzar a Rezar'), matching: find.byType(FilledButton)));
      expect(boton.bottom, lessThanOrEqualTo(640 - 48), reason: 'el botón termina en ${boton.bottom}');
    });
  }
}
