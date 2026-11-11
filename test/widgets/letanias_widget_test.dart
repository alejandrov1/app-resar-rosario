import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/letanias_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final texto = oracionesFinales.first.text;

  test('agrupa las letanías en 4 bloques', () {
    final grupos = analizarLetanias(texto);
    expect(grupos, hasLength(4));
    expect(grupos[0].map((l) => l.invocacion), ['Señor, ten piedad', 'Cristo, ten piedad', 'Señor, ten piedad']);
    expect(grupos[0].every((l) => l.respuesta == null), isTrue);
  });

  test('separa la invocación de la respuesta', () {
    final grupos = analizarLetanias(texto);
    expect(grupos[2].first, const LineaLetania('Dios, Padre celestial,', 'Ten misericordia de nosotros.'));
    expect(grupos[3].first, const LineaLetania('Santa María,', 'Ruega por nosotros.'));
    expect(grupos[3].last, const LineaLetania('Reina de la paz,', 'Ruega por nosotros.'));
  });

  test('no pierde ninguna línea', () {
    final lineas = texto.split('\n').where((l) => l.trim().isNotEmpty).length;
    expect(analizarLetanias(texto).expand((g) => g), hasLength(lineas));
  });

  testWidgets('muestra las respuestas', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: SingleChildScrollView(child: LetaniasWidget(texto: texto, colores: SeccionesTema.claro.finales)),
      ),
    ));
    expect(find.textContaining('Ruega por nosotros.', findRichText: true), findsWidgets);
  });

  testWidgets('la pantalla de rezo usa el formato de letanías', (tester) async {
    final sesion = RosarioSession(reloj: () => lunes)..comenzar();
    for (var i = 0; i < 83; i++) {
      sesion.siguiente();
    }
    await tester.pumpWidget(envolver(const RezoScreen(), preferencias: await preferenciasDePrueba(), sesion: sesion));
    await tester.pumpAndSettle();
    expect(find.byType(LetaniasWidget), findsOneWidget);
  });
}
