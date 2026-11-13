import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relación de contraste WCAG 2.1 entre dos colores.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  final temas = <String, ThemeData>{
    'claro': AppTheme.claro(),
    'oscuro': AppTheme.oscuro(),
    'alto contraste claro': AppTheme.claro(altoContraste: true),
    'alto contraste oscuro': AppTheme.oscuro(altoContraste: true),
  };

  for (final MapEntry(key: nombre, value: tema) in temas.entries) {
    group(nombre, () {
      final secciones = tema.extension<SeccionesTema>()!;
      final tarjeta = tema.colorScheme.surfaceContainerLow;
      final minimoAcento = nombre.startsWith('alto') ? 7.0 : 4.5;

      for (final seccion in SeccionRosario.values) {
        final c = secciones.de(seccion);
        test('${seccion.name}: texto del botón', () {
          expect(contraste(c.sobreBoton, c.boton), greaterThanOrEqualTo(4.5));
        });
        test('${seccion.name}: acento sobre el recuadro', () {
          expect(contraste(c.acento, c.suave), greaterThanOrEqualTo(minimoAcento));
        });
        test('${seccion.name}: acento sobre la tarjeta', () {
          expect(contraste(c.acento, tarjeta), greaterThanOrEqualTo(4.5));
        });
      }

      test('título del inicio sobre su fondo', () {
        for (final fondo in secciones.fondoInicio) {
          expect(contraste(secciones.tituloInicio, fondo), greaterThanOrEqualTo(4.5));
        }
      });

      test('borde de las cuentas rezadas visible (3:1)', () {
        expect(contraste(secciones.bordeCuenta, tarjeta), greaterThanOrEqualTo(3));
      });
    });
  }

  test('cada tema usa su propia variante', () {
    expect(AppTheme.claro().extension<SeccionesTema>(), same(SeccionesTema.claro));
    expect(AppTheme.oscuro().extension<SeccionesTema>(), same(SeccionesTema.oscuro));
    expect(AppTheme.claro(altoContraste: true).extension<SeccionesTema>(), same(SeccionesTema.altoContrasteClaro));
    expect(AppTheme.oscuro(altoContraste: true).extension<SeccionesTema>(), same(SeccionesTema.altoContrasteOscuro));
  });
}
