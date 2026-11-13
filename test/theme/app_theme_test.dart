import 'dart:io';

import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/contraste.dart';

double altoMinimo(ButtonStyle? estilo) => estilo!.minimumSize!.resolve(<WidgetState>{})!.height;

void main() {
  test('botones de 48 de alto por defecto', () {
    final tema = AppTheme.claro();
    expect(altoMinimo(tema.filledButtonTheme.style), 48);
    expect(altoMinimo(tema.outlinedButtonTheme.style), 48);
  });

  test('botones grandes de 64 de alto', () {
    final tema = AppTheme.oscuro(botonesGrandes: true);
    expect(altoMinimo(tema.filledButtonTheme.style), 64);
    expect(altoMinimo(tema.outlinedButtonTheme.style), 64);
  });

  test('claro y oscuro', () {
    expect(AppTheme.claro().brightness, Brightness.light);
    expect(AppTheme.oscuro().brightness, Brightness.dark);
  });

  test('alto contraste cambia los colores del esquema', () {
    expect(AppTheme.claro(altoContraste: true).colorScheme.primary, isNot(AppTheme.claro().colorScheme.primary));
  });

  test('el tema no escala el texto: el tamaño se aplica una sola vez en la app (E4)', () {
    expect(AppTheme.claro().textTheme.bodyLarge!.fontSize, 16);
  });

  test('incluye los colores de cada sección', () {
    final secciones = AppTheme.claro().extension<SeccionesTema>()!;
    expect(secciones.de(SeccionRosario.misterio), same(secciones.misterio));
  });

  testWidgets('las oraciones usan Lora', (tester) async {
    late TextStyle estilo;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Builder(builder: (context) {
        estilo = AppTheme.oracion(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(estilo.fontFamily, 'Lora');
  });

  test('la fuente y su licencia están en el proyecto', () {
    for (final archivo in ['Lora-Variable.ttf', 'Lora-Italic-Variable.ttf', 'OFL.txt']) {
      expect(File('assets/fonts/$archivo').existsSync(), isTrue, reason: archivo);
    }
  });

  group('cada estilo de texto del tema tiene color legible (H1)', () {
    final temas = <String, ThemeData>{
      'claro': AppTheme.claro(),
      'oscuro': AppTheme.oscuro(),
      'claro alto contraste': AppTheme.claro(altoContraste: true),
      'oscuro alto contraste': AppTheme.oscuro(altoContraste: true),
    };
    for (final MapEntry(key: nombre, value: tema) in temas.entries) {
      testWidgets(nombre, (tester) async {
        late TextTheme textos;
        await tester.pumpWidget(MaterialApp(
          theme: tema,
          home: Builder(builder: (context) {
            textos = Theme.of(context).textTheme;
            return const SizedBox();
          }),
        ));
        final estilos = <String, TextStyle?>{
          'displayLarge': textos.displayLarge,
          'displayMedium': textos.displayMedium,
          'displaySmall': textos.displaySmall,
          'headlineLarge': textos.headlineLarge,
          'headlineMedium': textos.headlineMedium,
          'headlineSmall': textos.headlineSmall,
          'titleLarge': textos.titleLarge,
          'titleMedium': textos.titleMedium,
          'titleSmall': textos.titleSmall,
          'bodyLarge': textos.bodyLarge,
          'bodyMedium': textos.bodyMedium,
          'bodySmall': textos.bodySmall,
          'labelLarge': textos.labelLarge,
          'labelMedium': textos.labelMedium,
          'labelSmall': textos.labelSmall,
        };
        for (final MapEntry(key: n, value: estilo) in estilos.entries) {
          expect(estilo?.color, isNotNull, reason: '$nombre: $n sin color');
          expect(estilo!.fontSize, isNotNull, reason: '$nombre: $n sin tamaño');
          expect(contraste(estilo.color!, tema.colorScheme.surface), greaterThanOrEqualTo(4.5),
              reason: '$nombre: $n');
        }
      });
    }
  });
}
