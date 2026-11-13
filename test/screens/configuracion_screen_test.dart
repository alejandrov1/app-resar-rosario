import 'package:app_resar_rosario/screens/configuracion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cambiar tema, contraste y botones se refleja en las preferencias', (tester) async {
    final preferencias = await preferenciasDePrueba();
    await tester.pumpWidget(envolver(const ConfiguracionScreen(), preferencias: preferencias));

    await tester.tap(find.text('Alto contraste'));
    await tester.tap(find.text('Botones grandes'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Oscuro'), 200);
    await tester.tap(find.text('Oscuro'));
    await tester.pump();

    expect(preferencias.useHighContrast, isTrue);
    expect(preferencias.useLargeButtons, isTrue);
    expect(preferencias.themeMode, ThemeMode.dark);
  });

  testWidgets('restablecer pide confirmación y vuelve a los valores por defecto', (tester) async {
    final preferencias = await preferenciasDePrueba({'pref_large_buttons': true});
    await tester.pumpWidget(envolver(const ConfiguracionScreen(), preferencias: preferencias));

    await tester.scrollUntilVisible(find.text('Restablecer configuración'), 200);
    await tester.tap(find.text('Restablecer configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restablecer'));
    await tester.pumpAndSettle();

    expect(preferencias.useLargeButtons, isFalse);
    expect(find.text('Configuración restablecida'), findsOneWidget);
  });
}
