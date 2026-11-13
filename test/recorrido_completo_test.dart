import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('se reza el rosario completo de principio a fin y se vuelve al inicio', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();

    // Momentos clave del recorrido: índice del paso → texto que debe verse.
    const hitos = {
      0: 'Oraciones Iniciales',
      3: 'Misterios Gozosos · 1/5',
      5: 'Misterio 1/5 · Ave María 1/10',
      14: 'Misterio 1/5 · Ave María 10/10',
      19: 'Misterios Gozosos · 2/5',
      67: 'Misterios Gozosos · 5/5',
      83: 'Oraciones Finales',
      92: 'Dulce Madre',
    };

    for (var paso = 0; paso < 93; paso++) {
      final esperado = hitos[paso];
      if (esperado != null) {
        expect(find.text(esperado), findsOneWidget, reason: 'paso $paso');
      }
      await tester.tap(find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
