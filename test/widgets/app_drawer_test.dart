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

  testWidgets('el menú muestra las opciones, sin repetir el misterio del día', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Misterios del día'), findsNothing);
    for (final opcion in ['Agendar Rosario', 'Configuración', 'Acerca de']) {
      expect(find.text(opcion), findsOneWidget);
    }
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
