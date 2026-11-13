import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auditor_contraste.dart';

void main() {
  Future<List<String>> auditar(WidgetTester tester, Widget contenido) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: contenido))));
    return fallasDeContraste(tester, 'prueba');
  }

  testWidgets('detecta un texto sin color', (tester) async {
    final fallas = await auditar(tester, const Text('x', style: TextStyle(inherit: false, fontSize: 14)));
    expect(fallas.single, contains('no tiene color'));
  });

  testWidgets('detecta poco contraste contra el fondo real', (tester) async {
    final fallas = await auditar(
      tester,
      const ColoredBox(color: Color(0xFFFFFFFF), child: Text('x', style: TextStyle(color: Color(0xFFBBBBBB)))),
    );
    expect(fallas.single, contains(':1'));
  });

  testWidgets('en un degradado cuenta el color con peor contraste', (tester) async {
    final fallas = await auditar(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)])),
        child: Text('x', style: TextStyle(color: Color(0xFF000000))),
      ),
    );
    expect(fallas, isNotEmpty);
  });

  testWidgets('acepta texto oscuro sobre fondo claro', (tester) async {
    final fallas = await auditar(
      tester,
      const ColoredBox(color: Color(0xFFFFFFFF), child: Text('x', style: TextStyle(color: Color(0xFF222222)))),
    );
    expect(fallas, isEmpty);
  });
}
