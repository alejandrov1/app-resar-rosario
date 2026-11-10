import 'package:flutter/material.dart';

import '../models/prayer_models.dart';

/// Colores de una sección del rosario.
@immutable
class SeccionColores {
  const SeccionColores({
    required this.fondo,
    required this.boton,
    required this.sobreBoton,
    required this.suave,
    required this.acento,
    this.borde,
  });

  /// Degradado detrás de la tarjeta de la oración.
  final List<Color> fondo;

  /// Fondo del botón principal.
  final Color boton;

  /// Texto e íconos sobre [boton].
  final Color sobreBoton;

  /// Fondo de los recuadros de encabezado.
  final Color suave;

  /// Texto de acento sobre la tarjeta o sobre [suave].
  final Color acento;

  /// Borde de los recuadros (solo en alto contraste).
  final Color? borde;

  static SeccionColores lerp(SeccionColores a, SeccionColores b, double t) => SeccionColores(
        fondo: [for (var i = 0; i < a.fondo.length; i++) Color.lerp(a.fondo[i], b.fondo[i], t)!],
        boton: Color.lerp(a.boton, b.boton, t)!,
        sobreBoton: Color.lerp(a.sobreBoton, b.sobreBoton, t)!,
        suave: Color.lerp(a.suave, b.suave, t)!,
        acento: Color.lerp(a.acento, b.acento, t)!,
        borde: Color.lerp(a.borde, b.borde, t),
      );
}

/// Colores propios de la app que cambian con el tema.
@immutable
class SeccionesTema extends ThemeExtension<SeccionesTema> {
  const SeccionesTema({
    required this.iniciales,
    required this.misterio,
    required this.finales,
    required this.fondoInicio,
    required this.tituloInicio,
    required this.cuenta,
    required this.bordeCuenta,
  });

  final SeccionColores iniciales;
  final SeccionColores misterio;
  final SeccionColores finales;

  /// Degradado de la pantalla de inicio.
  final List<Color> fondoInicio;

  /// Título y textos sobre [fondoInicio].
  final Color tituloInicio;

  /// Relleno y borde de las cuentas del rosario ya rezadas.
  final Color cuenta;
  final Color bordeCuenta;

  /// Estilo actual de la app: azul (iniciales), morado (misterios), verde (finales).
  static const claro = SeccionesTema(
    iniciales: SeccionColores(
      fondo: [Color(0xFF1E40AF), Color(0xFF2563EB)],
      boton: Color(0xFF2563EB),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFE3F2FD),
      acento: Color(0xFF1E40AF),
    ),
    misterio: SeccionColores(
      fondo: [Color(0xFF6B21A8), Color(0xFF9333EA)],
      boton: Color(0xFF9333EA),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFF3E5F5),
      acento: Color(0xFF6B21A8),
    ),
    finales: SeccionColores(
      fondo: [Color(0xFF166534), Color(0xFF16A34A)],
      // Un tono más oscuro que el original para que el texto blanco cumpla contraste AA.
      boton: Color(0xFF15803D),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFE8F5E9),
      acento: Color(0xFF166534),
    ),
    fondoInicio: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
    tituloInicio: Color(0xFF1E3A8A),
    cuenta: Color(0xFFFBBF24),
    bordeCuenta: Color(0xFFB45309),
  );

  SeccionColores de(SeccionRosario seccion) => switch (seccion) {
        SeccionRosario.iniciales => iniciales,
        SeccionRosario.misterio => misterio,
        SeccionRosario.finales => finales,
      };

  @override
  SeccionesTema copyWith({
    SeccionColores? iniciales,
    SeccionColores? misterio,
    SeccionColores? finales,
    List<Color>? fondoInicio,
    Color? tituloInicio,
    Color? cuenta,
    Color? bordeCuenta,
  }) {
    return SeccionesTema(
      iniciales: iniciales ?? this.iniciales,
      misterio: misterio ?? this.misterio,
      finales: finales ?? this.finales,
      fondoInicio: fondoInicio ?? this.fondoInicio,
      tituloInicio: tituloInicio ?? this.tituloInicio,
      cuenta: cuenta ?? this.cuenta,
      bordeCuenta: bordeCuenta ?? this.bordeCuenta,
    );
  }

  @override
  SeccionesTema lerp(covariant SeccionesTema? other, double t) {
    if (other == null) return this;
    return SeccionesTema(
      iniciales: SeccionColores.lerp(iniciales, other.iniciales, t),
      misterio: SeccionColores.lerp(misterio, other.misterio, t),
      finales: SeccionColores.lerp(finales, other.finales, t),
      fondoInicio: [
        for (var i = 0; i < fondoInicio.length; i++) Color.lerp(fondoInicio[i], other.fondoInicio[i], t)!,
      ],
      tituloInicio: Color.lerp(tituloInicio, other.tituloInicio, t)!,
      cuenta: Color.lerp(cuenta, other.cuenta, t)!,
      bordeCuenta: Color.lerp(bordeCuenta, other.bordeCuenta, t)!,
    );
  }
}

extension SeccionesDelContexto on BuildContext {
  SeccionesTema get secciones => Theme.of(this).extension<SeccionesTema>() ?? SeccionesTema.claro;

  SeccionColores coloresDe(SeccionRosario seccion) => secciones.de(seccion);
}
