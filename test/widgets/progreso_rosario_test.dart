import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/progreso_rosario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pasos = construirPasos();

  test('etiquetas de progreso', () {
    expect(etiquetaProgreso(pasos[0]), 'Oraciones iniciales · 1/3');
    expect(etiquetaProgreso(pasos[3]), 'Misterio 1/5');
    expect(etiquetaProgreso(pasos[5]), 'Misterio 1/5 · Ave María 1/10');
    expect(etiquetaProgreso(pasos[14]), 'Misterio 1/5 · Ave María 10/10');
    expect(etiquetaProgreso(pasos[92]), 'Oraciones finales · 10/10');
  });

  testWidgets('muestra la etiqueta y la barra, y la anuncia al lector de pantalla', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: ProgresoRosario(paso: pasos[5], progreso: 6 / 93, colores: SeccionesTema.claro.misterio),
      ),
    ));
    expect(find.text('Misterio 1/5 · Ave María 1/10'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Progreso del rosario: Misterio 1/5 · Ave María 1/10, 6 por ciento$')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
