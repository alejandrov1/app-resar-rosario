import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
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

  testWidgets('primer paso: oraciones iniciales, sin botón Atrás', (tester) async {
    await mostrarEnPaso(tester, 0);
    expect(find.text('Oraciones Iniciales'), findsOneWidget);
    expect(find.text('Señal de la Cruz'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.text('Atrás'), findsNothing);
  });

  testWidgets('Continuar avanza y aparece Atrás', (tester) async {
    await mostrarEnPaso(tester, 0);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Acto de contrición'), findsOneWidget);
    expect(find.text('Atrás'), findsOneWidget);
  });

  testWidgets('anuncio del primer misterio', (tester) async {
    await mostrarEnPaso(tester, 3);
    expect(find.text('Misterios Gozosos · 1/5'), findsOneWidget);
    expect(find.text('1° Misterio Gozoso'), findsOneWidget);
    expect(find.text('Medita en este Misterio'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsNWidgets(2));
  });

  testWidgets('Ave María con sus cuentas', (tester) async {
    await mostrarEnPaso(tester, 5);
    expect(find.text('Ave María (1°)'), findsOneWidget);
    expect(find.text('Misterio 1/5 · Ave María 1/10'), findsOneWidget);
    expect(find.byType(RosaryBeadsWidget), findsOneWidget);
  });

  testWidgets('el último paso dice Terminar Rosario y regresa al inicio', (tester) async {
    final sesion = await mostrarEnPaso(tester, 92);
    expect(find.text('Dulce Madre'), findsOneWidget);
    await tester.tap(find.text('Terminar Rosario'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('el botón Atrás del sistema retrocede un paso', (tester) async {
    final sesion = await mostrarEnPaso(tester, 2);
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(sesion.indice, 1);
  });
}
