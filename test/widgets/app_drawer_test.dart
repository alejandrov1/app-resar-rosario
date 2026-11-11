import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

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

  testWidgets('el menú muestra el misterio de hoy y todas las opciones', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Gozosos · Lunes'), findsOneWidget);
    for (final opcion in ['Misterios del día', 'Agendar Rosario', 'Configuración', 'Acerca de']) {
      expect(find.text(opcion), findsOneWidget);
    }
  });

  testWidgets('abre el diálogo con los 5 misterios y se cierra', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Misterios Gozosos'), findsNothing);
  });

  testWidgets('el menú muestra la versión instalada', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Versión 1.2.3'), findsOneWidget);
  });

  testWidgets('Acerca de muestra versión y compilación', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();
    expect(find.text('1.2.3 (4)'), findsOneWidget);
  });
}
