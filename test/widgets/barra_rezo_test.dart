import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/barra_rezo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pasos = construirPasos();

  test('nombre y avance de cada sección', () {
    expect(nombreSeccion(pasos[0], TipoMisterio.gozosos), 'Oraciones iniciales');
    expect(avanceSeccion(pasos[0]), '1 de 3');
    expect(nombreSeccion(pasos[3], TipoMisterio.luminosos), 'Misterios Luminosos');
    expect(avanceSeccion(pasos[3]), '1 de 5');
    expect(avanceSeccion(pasos[14]), '1 de 5');
    expect(avanceSeccion(pasos[19]), '2 de 5');
    expect(avanceSeccion(pasos[67]), '5 de 5');
    expect(nombreSeccion(pasos[83], TipoMisterio.gozosos), 'Oraciones finales');
    expect(avanceSeccion(pasos[83]), '1 de 10');
    expect(avanceSeccion(pasos[92]), '10 de 10');
  });

  Future<List<int>> mostrar(WidgetTester tester) async {
    final salidas = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: BarraRezo(
          paso: pasos[3],
          tipo: TipoMisterio.gozosos,
          progreso: 0.25,
          colores: SeccionesTema.claro.misterio,
          onSalir: () => salidas.add(1),
        ),
      ),
    ));
    return salidas;
  }

  testWidgets('muestra la sección y su avance en un solo texto', (tester) async {
    await mostrar(tester);
    expect(find.text('Misterios Gozosos · 1 de 5'), findsOneWidget);
  });

  testWidgets('anuncia el avance total al lector de pantalla', (tester) async {
    final handle = tester.ensureSemantics();
    await mostrar(tester);
    expect(find.bySemanticsLabel('Progreso del rosario: 25 por ciento'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el botón de inicio pregunta antes de salir', (tester) async {
    final salidas = await mostrar(tester);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir del rosario?'), findsOneWidget);
    expect(find.text('Se perderá el avance de este rosario.'), findsOneWidget);
    await tester.tap(find.text('Seguir rezando'));
    await tester.pumpAndSettle();
    expect(salidas, isEmpty);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(salidas, [1]);
  });
}
