import 'package:flutter/painting.dart';

/// Medidas compartidas de la interfaz. Los colores viven en `app_theme.dart` y `seccion_colores.dart`,
/// salvo los de la foto del rosario, que no cambian con la variante del tema.
abstract final class AppTokens {
  static const double espacioXS = 4;
  static const double espacioS = 8;
  static const double espacioM = 16;
  static const double espacioL = 24;
  static const double espacioXL = 32;

  static const double radioS = 12;
  static const double radioM = 16;
  static const double radioL = 24;

  /// Altura mínima de los botones.
  static const double botonNormal = 48;
  static const double botonGrande = 64;

  /// Ancho máximo del contenido (tabletas).
  static const double anchoMaximo = 600;

  /// Fondo blanco que enmarca la foto del rosario (pertenece a la foto, igual en todas las variantes).
  static const Color fondoFoto = Color(0xFFFFFFFF);

  /// Sombra bajo la foto del rosario (negro al 20 %).
  static const Color sombraFoto = Color(0x33000000);
}
