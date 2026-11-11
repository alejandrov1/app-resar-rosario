import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'seccion_colores.dart';

/// Temas de la app. El tamaño de letra NO se escala aquí: lo hace `MaterialApp.builder`.
abstract final class AppTheme {
  static const Color semilla = Color(0xFF1E3A8A);

  static ThemeData claro({bool altoContraste = false, bool botonesGrandes = false}) =>
      _crear(Brightness.light, altoContraste: altoContraste, botonesGrandes: botonesGrandes);

  static ThemeData oscuro({bool altoContraste = false, bool botonesGrandes = false}) =>
      _crear(Brightness.dark, altoContraste: altoContraste, botonesGrandes: botonesGrandes);

  /// Estilo del texto de las oraciones.
  static TextStyle oracion(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontFamily: 'Lora', fontSize: 18, height: 1.6);

  static ThemeData _crear(Brightness brillo, {required bool altoContraste, required bool botonesGrandes}) {
    final esquema = ColorScheme.fromSeed(
      seedColor: semilla,
      brightness: brillo,
      contrastLevel: altoContraste ? 1.0 : 0.0,
    );
    final alto = botonesGrandes ? AppTokens.botonGrande : AppTokens.botonNormal;
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioM));
    const textoBoton = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    final base = ThemeData(colorScheme: esquema);

    return base.copyWith(
      // ThemeData no trae tamaños de letra: se toman de la escala M3 (bodyLarge = 16).
      textTheme: base.textTheme.merge(Typography.englishLike2021),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: Size(64, alto), shape: forma, textStyle: textoBoton),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: Size(64, alto), shape: forma, textStyle: textoBoton),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: Size(64, alto), shape: forma),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radioL),
          side: altoContraste ? BorderSide(color: esquema.onSurface, width: 2) : BorderSide.none,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[SeccionesTema.para(brillo: brillo, altoContraste: altoContraste)],
    );
  }
}
