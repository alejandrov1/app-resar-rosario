import 'package:app_resar_rosario/screens/principal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inicio muestra el día y el misterio, y empieza a rezar', (tester) async {
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('Misterios Gozosos'), findsOneWidget);

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    expect(find.text('Oraciones Iniciales'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
