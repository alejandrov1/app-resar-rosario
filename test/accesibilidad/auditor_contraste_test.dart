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

  testWidgets('mezcla las capas translúcidas con lo que hay debajo', (tester) async {
    // Negro al 70% sobre blanco da un gris oscuro: el texto blanco se lee. Sobre el blanco solo, no se leería.
    final fallas = await auditar(
      tester,
      const ColoredBox(
        color: Color(0xFFFFFFFF),
        child: ColoredBox(color: Color(0xB3000000), child: Text('x', style: TextStyle(color: Color(0xFFFFFFFF)))),
      ),
    );
    expect(fallas, isEmpty);
  });

  group('texto grande', () {
    // Gris 0x888888 sobre blanco: unos 3.5:1, entre el mínimo de texto grande (3) y el de texto normal (4.5).
    Future<List<String>> conTamano(WidgetTester tester, double tamano, [FontWeight? peso]) {
      return auditar(
        tester,
        ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Text('x', style: TextStyle(color: const Color(0xFF888888), fontSize: tamano, fontWeight: peso)),
        ),
      );
    }

    testWidgets('a 14 se exige 4.5:1', (tester) async {
      expect(await conTamano(tester, 14), isNotEmpty);
    });

    testWidgets('a 24 basta 3:1', (tester) async {
      expect(await conTamano(tester, 24), isEmpty);
    });

    testWidgets('a 19 en negrita basta 3:1', (tester) async {
      expect(await conTamano(tester, 19, FontWeight.bold), isEmpty);
    });
  });

  group('controles', () {
    Future<List<String>> boton(WidgetTester tester, {required bool habilitado}) {
      return auditar(
        tester,
        FilledButton(
          onPressed: habilitado ? () {} : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFFFFF),
            foregroundColor: const Color(0xFFBBBBBB),
          ),
          child: const Text('x'),
        ),
      );
    }

    testWidgets('no revisa el texto de un botón deshabilitado', (tester) async {
      expect(await boton(tester, habilitado: false), isEmpty);
    });

    testWidgets('sí revisa el mismo botón habilitado', (tester) async {
      expect(await boton(tester, habilitado: true), isNotEmpty);
    });
  });
}
