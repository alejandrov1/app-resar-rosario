import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import '../theme/barras_sistema.dart';
import '../theme/seccion_colores.dart';

/// Estructura de cada paso del rezo: el fondo de la sección y una tarjeta con la [barra] arriba,
/// el [cuerpo] que se desplaza y los botones fijos abajo.
class PasoOracionLayout extends StatelessWidget {
  const PasoOracionLayout({
    super.key,
    required this.colores,
    required this.barra,
    required this.cuerpo,
    required this.onSiguiente,
    this.onAnterior,
    this.textoSiguiente = 'Continuar',
    this.claveCuerpo,
  });

  /// Con menos alto que esto (horizontal con letra grande), la barra se desplaza junto con el cuerpo
  /// para que los botones nunca se corten.
  static const double altoMinimoBarraFija = 400;

  /// Hasta esta escala de letra el mínimo es [altoMinimoBarraFija]. Por encima crece en proporción a la letra,
  /// porque la barra (con su contador sin partir) ocupa más líneas.
  static const double escalaSinAjusteBarra = 2;

  final SeccionColores colores;
  final Widget barra;

  /// Contenido del paso. No debe tener su propio desplazamiento: el layout ya lo da.
  final Widget cuerpo;
  final VoidCallback onSiguiente;

  /// Si es `null`, no se muestra el botón para retroceder.
  final VoidCallback? onAnterior;
  final String textoSiguiente;

  /// Cambia en cada paso para que el cuerpo empiece arriba.
  final Key? claveCuerpo;

  @override
  Widget build(BuildContext context) {
    // El fondo cambia con la variante (degradado saturado, blanco o negro): los iconos se eligen según el color
    // real de arriba (barra de estado) y de abajo (barra de navegación).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: estiloBarras(iconosSobre(colores.fondo.first), iconosNavegacion: iconosSobre(colores.fondo.last)),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colores.fondo),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.espacioM),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.espacioL),
                      child: LayoutBuilder(
                        builder: (context, limites) {
                          final escala = MediaQuery.textScalerOf(context).scale(1);
                          final factor = escala > escalaSinAjusteBarra ? escala / escalaSinAjusteBarra : 1.0;
                          final barraFija = limites.maxHeight >= altoMinimoBarraFija * factor;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (barraFija) ...[barra, const SizedBox(height: AppTokens.espacioM)],
                              Expanded(
                                child: SingleChildScrollView(
                                  key: claveCuerpo,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (!barraFija) ...[barra, const SizedBox(height: AppTokens.espacioM)],
                                      cuerpo,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppTokens.espacioM),
                              _Botones(
                                colores: colores,
                                onAnterior: onAnterior,
                                onSiguiente: onSiguiente,
                                texto: textoSiguiente,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado para retroceder y botón principal que ocupa el resto. Las etiquetas no se parten:
/// si no caben, se reducen.
class _Botones extends StatelessWidget {
  const _Botones({required this.colores, required this.onAnterior, required this.onSiguiente, required this.texto});

  final SeccionColores colores;
  final VoidCallback? onAnterior;
  final VoidCallback onSiguiente;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final alto =
        Theme.of(context).filledButtonTheme.style?.minimumSize?.resolve(const <WidgetState>{})?.height ??
            AppTokens.botonNormal;
    return Row(
      children: [
        if (onAnterior != null) ...[
          IconButton.outlined(
            onPressed: onAnterior,
            tooltip: 'Paso anterior',
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              minimumSize: Size.square(alto),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioM)),
            ),
          ),
          const SizedBox(width: AppTokens.espacioM),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onSiguiente,
            style: FilledButton.styleFrom(backgroundColor: colores.boton, foregroundColor: colores.sobreBoton),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(texto, maxLines: 1),
                  const SizedBox(width: AppTokens.espacioS),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
