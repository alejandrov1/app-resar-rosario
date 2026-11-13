import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/screens/principal_screen.dart';
import 'package:app_resar_rosario/widgets/rosary_image_widget.dart';
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
    tester.semantics.tap(find.semantics.byLabel(RegExp('Ver los 5 misterios')));
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

  group('imagen y zona de desplazamiento del inicio', () {
    Future<double> altoDeLaImagen(WidgetTester tester, Size fisico, double escala) async {
      tester.view.physicalSize = fisico;
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': escala}));
      await tester.pumpAndSettle();
      return tester.widget<RosaryImageWidget>(find.byType(RosaryImageWidget)).height;
    }

    const vertical = Size(1080, 1920);
    const horizontal = Size(1920, 1080);

    testWidgets('la imagen se achica con la letra grande y nunca baja de 96', (tester) async {
      final a100 = await altoDeLaImagen(tester, vertical, 1.0);
      final a150 = await altoDeLaImagen(tester, vertical, 1.5);
      final a200 = await altoDeLaImagen(tester, vertical, 2.0);
      expect(a150, lessThan(a100));
      expect(a200, lessThanOrEqualTo(a150));
      for (final alto in [a100, a150, a200]) {
        expect(alto, greaterThanOrEqualTo(96));
      }
    });

    testWidgets('en horizontal la imagen es menor que en vertical y no baja de 96', (tester) async {
      for (final escala in [1.0, 1.5]) {
        final enVertical = await altoDeLaImagen(tester, vertical, escala);
        final enHorizontal = await altoDeLaImagen(tester, horizontal, escala);
        expect(enHorizontal, greaterThanOrEqualTo(96));
        expect(enHorizontal, lessThan(enVertical), reason: 'al ${(escala * 100).round()} %');
      }
    });

    for (final escala in [1.0, 1.5]) {
      testWidgets('sobre el botón fijo queda zona de desplazamiento al ${(escala * 100).round()} %', (tester) async {
        await altoDeLaImagen(tester, vertical, escala);
        final zona = tester.getSize(find.byType(SingleChildScrollView).first);
        expect(zona.height, greaterThanOrEqualTo(96), reason: 'la zona mide ${zona.height}');
      });
    }
  });
}
