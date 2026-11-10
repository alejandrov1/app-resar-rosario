import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
