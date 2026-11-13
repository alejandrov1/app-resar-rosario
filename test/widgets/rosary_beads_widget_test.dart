import 'package:app_resar_rosario/widgets/rosary_beads_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mostrar(WidgetTester tester, {required int actual}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RosaryBeadsWidget(current: actual, total: 10)),
      ),
    );
  }

  testWidgets('muestra una cuenta por cada Ave María', (tester) async {
    await mostrar(tester, actual: 3);
    for (var i = 0; i < 10; i++) {
      expect(find.byKey(ValueKey('cuenta-$i')), findsOneWidget);
    }
  });

  testWidgets('las cuentas hasta la actual se ven distintas a las pendientes', (tester) async {
    await mostrar(tester, actual: 3);
    BoxDecoration decoracion(int i) =>
        tester.widget<Container>(find.byKey(ValueKey('cuenta-$i'))).decoration! as BoxDecoration;
    expect(decoracion(3).color, equals(decoracion(0).color));
    expect(decoracion(3).color, isNot(equals(decoracion(4).color)));
  });

  testWidgets('las cuentas no se anuncian: el número ya está en el título de la oración', (tester) async {
    final handle = tester.ensureSemantics();
    await mostrar(tester, actual: 3); // ayudante que ya existe en el archivo
    expect(find.bySemanticsLabel(RegExp('Ave María')), findsNothing);
    handle.dispose();
  });
}
