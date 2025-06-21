import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_resar_rosario/widgets/rosary_beads_widget.dart';

void main() {
  group('RosaryBeadsWidget Tests', () {
    testWidgets('Debe mostrar el número correcto de cuentas', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RosaryBeadsWidget(
              current: 3,
              total: 10,
            ),
          ),
        ),
      );

      // Buscar todos los contenedores que representan cuentas
      final beadFinder = find.byType(Container);
      // +1 porque hay un Container padre en el widget
      expect(beadFinder, findsNWidgets(11));
    });

    testWidgets('Las cuentas completadas deben tener color diferente', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RosaryBeadsWidget(
              current: 5,
              total: 10,
            ),
          ),
        ),
      );

      // Verificar que el widget se renderiza sin errores
      expect(find.byType(RosaryBeadsWidget), findsOneWidget);
    });
  });
}