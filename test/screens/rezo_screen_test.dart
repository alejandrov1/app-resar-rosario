import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
import 'package:app_resar_rosario/widgets/barra_rezo.dart';
import 'package:app_resar_rosario/widgets/rosary_beads_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RosarioSession> mostrarEnPaso(WidgetTester tester, int indice) async {
    final sesion = RosarioSession(reloj: () => lunes)..comenzar();
    for (var i = 0; i < indice; i++) {
      sesion.siguiente();
    }
    await tester.pumpWidget(envolver(const RezoScreen(), preferencias: await preferenciasDePrueba(), sesion: sesion));
    await tester.pumpAndSettle();
    return sesion;
  }

  test('títulos del anuncio y de la oración', () {
    final pasos = construirPasos();
    expect(tituloAnuncio(pasos[19], TipoMisterio.luminosos), '2.º Misterio Luminoso');
    expect(tituloOracion(pasos[0]), 'Señal de la Cruz');
    expect(tituloOracion(pasos[7]), 'Ave María · 3 de 10');
  });

  testWidgets('primer paso: oraciones iniciales, sin botón para retroceder', (tester) async {
    await mostrarEnPaso(tester, 0);
    expect(find.text('Oraciones iniciales · 1 de 3'), findsOneWidget);
    expect(find.text('Señal de la Cruz'), findsOneWidget);
    expect(find.byTooltip('Paso anterior'), findsNothing);
  });

  testWidgets('Continuar avanza y aparece el botón para retroceder', (tester) async {
    await mostrarEnPaso(tester, 0);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Acto de contrición'), findsOneWidget);
    await tester.tap(find.byTooltip('Paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Señal de la Cruz'), findsOneWidget);
  });

  testWidgets('anuncio del primer misterio: cada dato una vez', (tester) async {
    await mostrarEnPaso(tester, 3);
    expect(find.text('Misterios Gozosos · 1 de 5'), findsOneWidget);
    expect(find.text('1.º Misterio Gozoso'), findsOneWidget);
    expect(find.text('Medita en este misterio.'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsOneWidget);
  });

  testWidgets('Ave María: título con su número, cuentas y el misterio como recordatorio', (tester) async {
    await mostrarEnPaso(tester, 5);
    expect(find.text('Ave María · 1 de 10'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsOneWidget);
    expect(find.byType(RosaryBeadsWidget), findsOneWidget);
  });

  testWidgets('cada paso muestra cada dato una sola vez (los 93)', (tester) async {
    final sesion = await mostrarEnPaso(tester, 0);
    for (var i = 0; i < 93; i++) {
      final paso = sesion.pasoActual;
      expect(find.textContaining(nombreSeccion(paso, sesion.tipoMisterio)), findsOneWidget, reason: 'paso $i: sección');
      expect(find.textContaining(avanceSeccion(paso)), findsOneWidget, reason: 'paso $i: avance');
      if (paso.seccion == SeccionRosario.misterio) {
        expect(find.textContaining(sesion.tituloMisterioActual), findsOneWidget, reason: 'paso $i: misterio');
      }
      if (paso.repeticion != null) {
        expect(find.textContaining('${paso.repeticion! + 1} de 10'), findsOneWidget, reason: 'paso $i: Ave María');
      }
      if (i < 92) {
        sesion.siguiente();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('el último paso dice Terminar Rosario y regresa al inicio', (tester) async {
    final sesion = await mostrarEnPaso(tester, 92);
    expect(find.text('Dulce Madre'), findsOneWidget);
    await tester.tap(find.text('Terminar Rosario'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('volver al inicio pide confirmación', (tester) async {
    final sesion = await mostrarEnPaso(tester, 10);
    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir rezando'));
    await tester.pumpAndSettle();
    expect(sesion.indice, 10);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('al avanzar, el texto vuelve arriba', (tester) async {
    // Pantalla chica para que dos pasos contiguos (letanías y Cordero de Dios) desborden.
    tester.view.physicalSize = const Size(360, 480) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final sesion = await mostrarEnPaso(tester, 83);
    ScrollPosition posicion() => tester.state<ScrollableState>(find.byType(Scrollable).first).position;

    expect(posicion().maxScrollExtent, greaterThan(0), reason: 'el paso 83 debe desbordar');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(posicion().pixels, greaterThan(0));

    sesion.siguiente();
    await tester.pumpAndSettle();
    expect(posicion().maxScrollExtent, greaterThan(0), reason: 'el paso 84 debe desbordar, o el tope ocultaría la falla');
    expect(posicion().pixels, 0);
  });

  testWidgets('el botón Atrás del sistema retrocede un paso', (tester) async {
    final sesion = await mostrarEnPaso(tester, 2);
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(sesion.indice, 1);
  });
}
