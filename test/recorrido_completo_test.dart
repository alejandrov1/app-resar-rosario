import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('se reza el rosario completo de principio a fin y se vuelve al inicio', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();

    // Momentos clave del recorrido: índice del paso → textos que deben verse una vez.
    const hitos = <int, List<String>>{
      0: ['Oraciones iniciales · 1 de 3', 'Señal de la Cruz'],
      3: ['Misterios Gozosos · 1 de 5', '1.º Misterio Gozoso'],
      5: ['Misterios Gozosos · 1 de 5', 'Ave María · 1 de 10'],
      14: ['Misterios Gozosos · 1 de 5', 'Ave María · 10 de 10'],
      19: ['Misterios Gozosos · 2 de 5', '2.º Misterio Gozoso'],
      67: ['Misterios Gozosos · 5 de 5', '5.º Misterio Gozoso'],
      83: ['Oraciones finales · 1 de 10', 'Letanías de la Santísima Virgen'],
      92: ['Oraciones finales · 10 de 10', 'Dulce Madre'],
    };

    for (var paso = 0; paso < 93; paso++) {
      for (final esperado in hitos[paso] ?? const <String>[]) {
        expect(find.text(esperado), findsOneWidget, reason: 'paso $paso: $esperado');
      }
      await tester.tap(find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
