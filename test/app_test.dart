import 'package:app_resar_rosario/app.dart';
import 'package:app_resar_rosario/screens/configuracion_screen.dart';
import 'package:app_resar_rosario/screens/inicio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arranca en la pantalla de inicio, en español (E9)', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    expect(find.text('Comenzar a Rezar'), findsOneWidget);
    final contexto = tester.element(find.byType(InicioScreen));
    expect(Localizations.localeOf(contexto).languageCode, 'es');
    expect(MaterialLocalizations.of(contexto).cancelButtonLabel, 'Cancelar');
  });

  testWidgets('el tamaño de texto se aplica una sola vez (E4)', (tester) async {
    final d = await dependenciasDePrueba(preferencias: {'pref_text_scale': 1.5});
    await tester.pumpWidget(SantoRosarioApp(preferencias: d.preferencias, notificaciones: d.notificaciones, reloj: () => lunes));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byType(InicioScreen));
    expect(MediaQuery.textScalerOf(contexto).scale(10), closeTo(15, 0.01));
    expect(Theme.of(contexto).textTheme.bodyLarge!.fontSize, 16);
  });

  testWidgets('el menú lateral abre Configuración (E2)', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfiguracionScreen), findsOneWidget);
    expect(find.text('Tamaño del texto'), findsOneWidget);
  });

  testWidgets('activar botones grandes cambia el tema de toda la app', (tester) async {
    await tester.pumpWidget(await appDePrueba(preferencias: {'pref_large_buttons': true}));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byType(InicioScreen));
    final alto = Theme.of(contexto).filledButtonTheme.style!.minimumSize!.resolve(<WidgetState>{})!.height;
    expect(alto, 64);
  });
}
