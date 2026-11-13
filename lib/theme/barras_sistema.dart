import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barras del sistema transparentes (la app dibuja hasta el borde) con iconos de brillo [iconos]:
/// `Brightness.dark` para fondos claros y `Brightness.light` para fondos oscuros.
SystemUiOverlayStyle estiloBarras(Brightness iconos) => SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconos,
      statusBarBrightness: iconos == Brightness.dark ? Brightness.light : Brightness.dark, // iOS: al revés
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconos,
      systemNavigationBarContrastEnforced: false,
    );

/// Iconos que se leen sobre el fondo del tema: oscuros en los temas claros y claros en los oscuros.
Brightness iconosParaTema(Brightness tema) => tema == Brightness.dark ? Brightness.light : Brightness.dark;
